local ttt = require("ttt")
local sys = require("ttt.system")
local json = require("ttt.json")
local storage = require("ttt.storage")

local state = {
  url = "",
  repo = "",
  prs = {},
  saved = {},
  status = "Enter a repository or PR URL, then Load",
  error = "",
  list_generation = 0,
  open_generation = 0,
}
local sidebar
local review
local open_pr

local function redraw()
  if sidebar then sidebar:redraw() end
end

local function fail(message)
  state.error = tostring(message):gsub("%s+$", "")
  ttt.log("error", state.error)
  redraw()
end

local function gh(args, body, callback)
  sys.exec_async("gh", args, { stdin = body or "" }, function(result)
    if result.exit_code ~= 0 then
      callback(nil, result.stderr ~= "" and result.stderr or result.stdout)
    else
      callback(result.stdout)
    end
    redraw()
  end)
end

local function decode(text)
  local ok, value = pcall(json.decode, text)
  if ok then return value end
  return nil, "GitHub returned invalid JSON"
end

local function repository(text)
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  text = text:gsub("^https://github.com/", ""):gsub("^http://github.com/", "")
  text = text:gsub("^github.com/", ""):gsub("/+$", ""):gsub("%.git$", "")
  local number = text:match("/pull/(%d+)$")
  local owner, repo = text:match("^([%w_.-]+)/([%w_.-]+)$")
  if not owner then owner, repo = text:match("^([%w_.-]+)/([%w_.-]+)/pull/%d+$") end
  if owner and repo and owner ~= "." and repo ~= "." and repo ~= ".." then
    return owner .. "/" .. repo, tonumber(number)
  end
end

local saved = storage.get("saved_repositories")
if type(saved) == "table" then
  local seen = {}
  for _, url in ipairs(saved) do
    local repo = type(url) == "string" and repository(url)
    if repo and not seen[repo:lower()] then
      seen[repo:lower()] = true
      state.saved[#state.saved + 1] = "https://github.com/" .. repo
    end
  end
end

local function save_repository()
  local repo = state.current and state.current.repo or repository(state.url)
  if not repo then ttt.notify("Load a repository first"); return end
  local url = "https://github.com/" .. repo
  local urls = {}
  for _, existing in ipairs(state.saved) do
    if existing:lower() == url:lower() then
      ttt.notify("Repository already saved")
      return
    end
    urls[#urls + 1] = existing
  end
  urls[#urls + 1] = url
  table.sort(urls)
  local ok, err = pcall(storage.set, "saved_repositories", urls)
  if not ok then fail(err); return end
  state.saved = urls
  ttt.notify("Saved " .. repo)
  redraw()
end

local function load_prs()
  if review and review.busy then return end
  local repo, number = repository(state.url)
  if not repo then
    fail("Enter a repository or pull request URL")
    return
  end
  state.list_generation = state.list_generation + 1
  state.open_generation = state.open_generation + 1
  local generation = state.list_generation
  state.repo, state.current, state.prs = repo, nil, {}
  state.error, state.status = "", "Loading pull requests…"
  local args = number and {"pr", "view", tostring(number), "--repo", repo,
      "--json", "number,title,author,isDraft,url"} or
      {"pr", "list", "--repo", repo, "--state", "open", "--limit", "100",
      "--json", "number,title,author,isDraft,url"}
  gh(args, nil, function(text, err)
    if generation ~= state.list_generation then return end
    if err then state.status = "Load failed"; fail(err); return end
    local prs, parse_err = decode(text)
    if not prs then fail(parse_err); return end
    state.prs = number and {prs} or prs
    state.list_status = #state.prs .. (number and " PR · " or " open PRs · ") .. repo
    state.status = state.list_status
    if number then open_pr(number) end
  end)
end

open_pr = function(number)
  if review and review.busy then return end
  if not ttt.open_changes then fail("Rebuild ttt with the draft open_changes API"); return end
  state.open_generation = state.open_generation + 1
  local generation, repo = state.open_generation, state.repo
  state.current, state.error = nil, ""
  state.status = "Opening PR #" .. number .. "…"
  gh({"api", "repos/" .. repo .. "/pulls/" .. number}, nil, function(text, err)
    if generation ~= state.open_generation then return end
    if err then fail(err); return end
    local pr, parse_err = decode(text)
    if not pr then fail(parse_err); return end
    gh({"pr", "diff", tostring(number), "--repo", repo}, nil, function(diff, diff_err)
      if generation ~= state.open_generation then return end
      if diff_err then fail(diff_err); return end
      local id, view_err = ttt.open_changes({
        id = pr.html_url,
        title = "PR #" .. number .. ": " .. pr.title,
        description = "@" .. pr.user.login .. " · " .. pr.html_url .. "\n\n" .. (pr.body or ""),
        diff = diff,
      })
      if not id then fail(view_err); return end
      state.current = {repo = repo, number = number, title = pr.title, sha = pr.head.sha, tab = id}
      state.status = state.list_status or ""
    end)
  end)
end

local function review_error(draft, message)
  draft.busy, draft.error = false, tostring(message)
  ttt.log("error", draft.error)
  ttt.notify(draft.error, "error")
  redraw()
end

local function finish_review(draft, message)
  draft.busy = false
  state.status = message
  if review == draft then
    ttt.close_dialog()
    review = nil
  end
  ttt.notify(message)
  redraw()
end

local function merge_pr(draft)
  local pr = draft.pr
  gh({"api", "--method", "PUT", "repos/" .. pr.repo .. "/pulls/" .. pr.number .. "/merge", "--input", "-"},
      json.encode({sha = pr.sha, merge_method = "squash"}), function(text, err)
    if err then review_error(draft, "Approved; merge failed: " .. err); return end
    local result, parse_err = decode(text)
    if not result or not result.merged then
      review_error(draft, "Approved; merge failed: " .. (parse_err or result.message or "GitHub refused the merge"))
      return
    end
    for i, item in ipairs(state.prs) do
      if item.number == pr.number then table.remove(state.prs, i); break end
    end
    state.current = nil
    finish_review(draft, "Approved and merged PR #" .. pr.number)
  end)
end

local function submit_review(draft, event)
  if draft.busy or draft.submitted then return end
  local message = draft.message
  if event == "COMMENT" and not message:match("%S") then
    review_error(draft, "Write a message before commenting")
    return
  end
  draft.busy, draft.error = true, ""
  local pr, merge = draft.pr, draft.merge and event == "APPROVE"
  gh({"api", "repos/" .. pr.repo .. "/pulls/" .. pr.number}, nil, function(text, err)
    if err then review_error(draft, err); return end
    local current, parse_err = decode(text)
    if not current then review_error(draft, parse_err); return end
    if current.state ~= "open" or current.head.sha ~= pr.sha then
      review_error(draft, "PR changed or closed. Reopen it before reviewing.")
      return
    end
    local payload = {event = event, body = message, commit_id = pr.sha}
    gh({"api", "--method", "POST", "repos/" .. pr.repo .. "/pulls/" .. pr.number .. "/reviews", "--input", "-"},
        json.encode(payload), function(_, submit_err)
      if submit_err then review_error(draft, submit_err); return end
      draft.submitted = true
      if merge then
        merge_pr(draft)
      else
        finish_review(draft, (event == "APPROVE" and "Approved PR #" or "Commented on PR #") .. pr.number)
      end
    end)
  end)
end

local function open_comments()
  local pr = state.current
  if not pr then ttt.notify("Open a pull request first"); return end
  local comments = {items = {}, pending = 3, errors = {}}
  ttt.open_drawer({side = "left", width = 85, min_width = 30, render = function(p)
    p:hstack({height = 1, gap = 1, render = function(row)
      row:label({text = "Comments · PR #" .. pr.number, style = "bold", padding_left = 1})
      row:button({label = "Close", padding_left = 2, padding_right = 2, on_click = ttt.close_drawer})
    end})
    p:divider()
    if comments.pending > 0 then p:label({text = "Loading comments…", style = "muted"}) end
    if #comments.errors > 0 then
      p:label({text = table.concat(comments.errors, "\n"), style = "danger"})
    end
    local sections = {}
    for _, item in ipairs(comments.items) do
      local c = item.comment
      local heading = "### @" .. (c.user and c.user.login or "ghost") .. " · " .. item.kind
      if c.state then heading = heading .. " · " .. c.state end
      local location = c.path and ("\n\n`" .. c.path .. ":" .. tostring(c.line or c.original_line or "?") .. "`") or ""
      sections[#sections + 1] = heading .. "\n\n" .. (c.created_at or c.submitted_at or "") .. location .. "\n\n" .. c.body
    end
    if #sections == 0 and comments.pending == 0 then sections[1] = "No comments yet." end
    p:markdown({text = table.concat(sections, "\n\n---\n\n"),
      padding_left = 1, padding_right = 1, full_width_dividers = true})
  end})
  local base = "repos/" .. pr.repo
  for _, source in ipairs({
    {path = base .. "/issues/" .. pr.number .. "/comments", kind = "Discussion"},
    {path = base .. "/pulls/" .. pr.number .. "/comments", kind = "Inline"},
    {path = base .. "/pulls/" .. pr.number .. "/reviews", kind = "Review"},
  }) do
    local kind = source.kind
    gh({"api", "--paginate", source.path, "--jq", ".[] | @json"}, nil, function(text, err)
      comments.pending = comments.pending - 1
      if err then
        comments.errors[#comments.errors + 1] = kind .. ": " .. tostring(err)
        return
      end
      for line in text:gmatch("[^\r\n]+") do
        local c, parse_err = decode(line)
        if not c then comments.errors[#comments.errors + 1] = parse_err; break end
        if type(c.body) == "string" and c.body:match("%S") then
          comments.items[#comments.items + 1] = {comment = c, kind = kind}
        end
      end
      table.sort(comments.items, function(a, b)
        local at, bt = a.comment.created_at or a.comment.submitted_at or "", b.comment.created_at or b.comment.submitted_at or ""
        if at ~= bt then return at < bt end
        return tostring(a.comment.id) < tostring(b.comment.id)
      end)
    end)
  end
end

local function open_review()
  if review and review.busy then return end
  if not state.current then ttt.notify("Open a pull request first"); return end
  if not ttt.open_dialog then fail("Rebuild ttt with the draft dialog API"); return end
  local draft = {pr = state.current, message = "", merge = false, busy = false, submitted = false, error = ""}
  local shown = ttt.open_dialog({
    title = "Review PR #" .. draft.pr.number,
    width = 76,
    height = 18,
    on_close = function() if review == draft and not draft.busy then review = nil end end,
    render = function(p)
      p:label({text = draft.pr.title, style = "bold"})
      local _, height = p:size()
      local rows = math.max(1, math.min(6, height - 9))
      p:label({text = "Message · Enter adds a line", style = "muted"})
      p:box({border = true, padding_left = 1, padding_right = 1, render = function(box)
        box:input({placeholder = "Write your review…", prefix = " ", multiline = true,
          min_rows = rows, max_rows = rows, autofocus = true,
          on_change = function(text) draft.message = text end})
      end})
      p:box({render = function() end})
      p:checkbox({label = "Merge after approval (squash)", checked = draft.merge,
        on_change = function(checked) if not draft.busy then draft.merge = checked end end})
      p:label({text = draft.busy and "Submitting…" or draft.error, style = draft.error ~= "" and "danger" or "muted"})
      p:hstack({height = 3, gap = 1, padding_top = 1, padding_bottom = 1, render = function(row)
        row:label("")
        row:button({label = "Cancel", padding_left = 2, padding_right = 2, on_click = function() if not draft.busy then ttt.close_dialog() end end})
        if draft.submitted then
          row:button({label = "Retry merge", padding_left = 2, padding_right = 2, on_click = function()
            if not draft.busy then draft.busy = true; draft.error = ""; merge_pr(draft) end
          end})
        else
          row:button({label = "Comment", padding_left = 2, padding_right = 2, on_click = function() submit_review(draft, "COMMENT") end})
          row:button({label = draft.merge and "&Approve & merge" or "&Approve", padding_left = 2, padding_right = 2,
            on_click = function() submit_review(draft, "APPROVE") end})
        end
      end})
    end,
  })
  if shown then review = draft else ttt.notify("Close the current dialog first") end
end

ttt.register({
  sidebar = {
    title = "PR Review",
    render = function(p)
      sidebar = p
      p:hstack({height = 1, gap = 1, render = function(row)
        row:input({value = state.url, placeholder = "https://github.com/owner/repo...", autofocus = true,
          on_change = function(text) state.url = text end,
          on_submit = function() load_prs() end})
        row:button({label = "Load", padding_left = 2, padding_right = 2, on_click = load_prs})
      end})
      p:divider()
      if state.current then
        p:hstack({height = 2, gap = 1, padding_bottom = 1, render = function(row)
          row:label({text = "#" .. state.current.number .. " " .. state.current.title, style = "muted"})
          row:dropdown({label = "⋮", entries = {
            {label = "Comments", command = "comments"},
            {label = "Review", command = "review"},
            {separator = true},
            {label = "Save repository", command = "save-repository"},
          }, on_menu = function(command)
            if command == "comments" then open_comments()
            elseif command == "review" then open_review()
            elseif command == "save-repository" then save_repository() end
          end})
        end})
        p:hstack({height = 1, gap = 1, render = function(row)
          row:label("")
          row:button({label = "Comments", padding_left = 2, padding_right = 2, on_click = open_comments})
          row:button({label = "Review", padding_left = 2, padding_right = 2, on_click = open_review})
        end})
        p:divider()
      end
      p:vstack({padding_left = 1, padding_right = 1, render = function(list)
        list:label({text = state.status, style = "muted"})
        if state.error ~= "" then list:label({text = state.error, style = "danger"}) end
        local items = {}
        for _, pr in ipairs(state.prs) do
          if not state.current or state.current.number ~= pr.number then
            items[#items + 1] = {id = tostring(pr.number), label = "#" .. pr.number .. " " .. pr.title,
              badge = pr.isDraft and "draft" or "", muted = pr.isDraft}
          end
        end
        list:list({items = items, on_command = function(command, node)
          if command == "activate" then open_pr(tonumber(node.id)) end
        end})
      end})
      if #state.saved > 0 then
        p:divider()
        p:label({text = "Saved repositories", style = "muted", padding_left = 1, padding_right = 1})
        local items = {}
        for _, url in ipairs(state.saved) do
          items[#items + 1] = {id = url, label = repository(url)}
        end
        p:box({height = 7, padding_left = 1, padding_right = 1, render = function(favorites)
          favorites:list({items = items, on_command = function(command, node)
            if command ~= "activate" or review and review.busy then return end
            state.url = node.id
            load_prs()
            redraw()
          end})
        end})
      end
    end,
  },
  commands = {
    {id = "pr-review.show", title = "PR Review: Show", handler = function() ttt.focus_panel("sidebar") end},
    {id = "pr-review.load", title = "PR Review: Load", handler = load_prs},
    {id = "pr-review.review", title = "PR Review: Review", handler = open_review},
    {id = "pr-review.comments", title = "PR Review: Comments", handler = open_comments},
  },
})
