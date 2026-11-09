local ttt = require("ttt")
local sys = require("ttt.system")
local json = require("ttt.json")
local storage = require("ttt.storage")
local ttt_text = require("ttt.text")

local state = {
  url = "",
  repo = "",
  prs = {},
  saved = {},
  pr_state = "open",
  loading = false,
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

local function load_prs(keep_current)
  if review and review.busy then return end
  local repo, number = repository(state.url)
  if not repo then
    fail("Enter a repository or pull request URL")
    return
  end
  if keep_current then number = nil end
  state.list_generation = state.list_generation + 1
  local generation = state.list_generation
  if not keep_current then
    state.open_generation = state.open_generation + 1
    state.current, state.opening = nil, number
  end
  state.repo, state.prs, state.single = repo, {}, number ~= nil
  state.error, state.loading = "", true
  local fields = "number,title,author,isDraft,state,url"
  local args = number and {"pr", "view", tostring(number), "--repo", repo, "--json", fields} or
      {"pr", "list", "--repo", repo, "--state", state.pr_state, "--limit", "100", "--json", fields}
  gh(args, nil, function(text, err)
    if generation ~= state.list_generation then return end
    state.loading = false
    if err then state.opening = nil; fail(err); return end
    local prs, parse_err = decode(text)
    if not prs then state.opening = nil; fail(parse_err); return end
    state.prs = number and {prs} or prs
    if number then open_pr(number) end
  end)
end

local function switch_pr_state(pr_state)
  if state.pr_state == pr_state then return end
  state.pr_state = pr_state
  if state.repo ~= "" then
    state.url = "https://github.com/" .. state.repo
    load_prs(true)
  end
  redraw()
end

open_pr = function(number)
  if review and review.busy then return end
  if not ttt.open_changes then fail("Rebuild ttt with the draft open_changes API"); return end
  state.open_generation = state.open_generation + 1
  local generation, repo = state.open_generation, state.repo
  state.current, state.error, state.opening = nil, "", number
  local function open_failed(message)
    state.opening = nil
    fail(message)
  end
  gh({"api", "repos/" .. repo .. "/pulls/" .. number}, nil, function(text, err)
    if generation ~= state.open_generation then return end
    if err then open_failed(err); return end
    local pr, parse_err = decode(text)
    if not pr then open_failed(parse_err); return end
    gh({"pr", "diff", tostring(number), "--repo", repo}, nil, function(diff, diff_err)
      if generation ~= state.open_generation then return end
      if diff_err then open_failed(diff_err); return end
      local id, view_err = ttt.open_changes({
        id = pr.html_url,
        title = "PR #" .. number .. ": " .. pr.title,
        description = "@" .. pr.user.login .. " · " .. pr.html_url .. "\n\n" .. (pr.body or ""),
        diff = diff,
      })
      if not id then open_failed(view_err); return end
      state.opening = nil
      state.current = {repo = repo, number = number, title = pr.title, sha = pr.head.sha, tab = id,
        comments = (tonumber(pr.comments) or 0) + (tonumber(pr.review_comments) or 0)}
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

local THREADS_QUERY = [[
query($owner: String!, $name: String!, $number: Int!, $endCursor: String) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 50, after: $endCursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id isResolved path line originalLine viewerCanResolve viewerCanReply
          comments(first: 50) { nodes { author { login } body createdAt } }
        }
      }
    }
  }
}]]
local RESOLVE_MUTATION = "mutation($id: ID!) { resolveReviewThread(input: {threadId: $id}) { thread { isResolved } } }"
local REPLY_MUTATION = "mutation($id: ID!, $body: String!) { addPullRequestReviewThreadReply(" ..
    "input: {pullRequestReviewThreadId: $id, body: $body}) { comment { id } } }"
local TAG_WIDTH = 8

local function summary_text(body)
  local text = body:gsub("<!%-%-.-%-%->", ""):gsub("<[^>]*>", " ")
  for line in text:gmatch("[^\r\n]+") do
    line = line:gsub("^[%s#>*%-]+", ""):gsub("[<>`*]", ""):gsub("%s+", " "):gsub("%s+$", "")
    if line ~= "" then return line end
  end
  return ""
end

-- ttt's markdown matches a </details> inside a quote as the end of the
-- enclosing disclosure, so quoted disclosure tags would end ours early.
local function strip_quoted_disclosures(body)
  return (("\n" .. body):gsub("\n(%s*>[^\n]*)", function(line)
    return "\n" .. line:gsub("</?details[^>]*>", ""):gsub("</?summary[^>]*>", "")
  end):sub(2))
end

local function comment_block(author, time, body)
  return "**@" .. author .. "** · " .. (time or "") .. "\n\n" .. strip_quoted_disclosures(body)
end

local function entry_markdown(entry, open)
  local tag = entry.tag .. string.rep(" ", TAG_WIDTH - ttt_text.width(entry.tag))
  local summary = ttt_text.truncate(tag .. "  " .. entry.summary, 72, "…")
  return "<details" .. (open and " open" or "") .. ">\n<summary>" .. summary ..
      "</summary>\n\n" .. entry.body .. "\n</details>"
end

local function thread_entry(t)
  local nodes = t.comments and t.comments.nodes or {}
  local first = nodes[1] or {}
  local parts = {}
  for _, c in ipairs(nodes) do
    parts[#parts + 1] = comment_block(c.author and c.author.login or "ghost", c.createdAt, c.body or "")
  end
  local where = (t.path or "?") .. ":" .. tostring(t.line or t.originalLine or "?")
  local author = first.author and first.author.login or "ghost"
  return {thread = t, time = first.createdAt or "", tag = t.isResolved and "Resolved" or "Open",
    summary = where .. " · @" .. author .. ": " .. summary_text(first.body or ""),
    body = table.concat(parts, "\n\n---\n\n")}
end

local function open_comments()
  local pr = state.current
  if not pr then ttt.notify("Open a pull request first"); return end
  local comments = {entries = {}, pending = 3, errors = {}, expand_all = false}
  local function sort_entries()
    table.sort(comments.entries, function(a, b) return a.time < b.time end)
  end
  local function thread_action(entry, args, done)
    local t = entry.thread
    t.busy = true
    gh(args, nil, function(_, err)
      t.busy = false
      if err then
        comments.errors[#comments.errors + 1] = tostring(err)
        ttt.notify(tostring(err), "error")
        return
      end
      done()
    end)
  end
  local function resolve(entry)
    thread_action(entry, {"api", "graphql", "-f", "query=" .. RESOLVE_MUTATION, "-f", "id=" .. entry.thread.id}, function()
      entry.thread.isResolved = true
      entry.tag = "Resolved"
    end)
  end
  local function send_reply(entry)
    local body = entry.reply or ""
    if not body:match("%S") then ttt.notify("Write a reply first"); return end
    thread_action(entry, {"api", "graphql", "-f", "query=" .. REPLY_MUTATION, "-f", "id=" .. entry.thread.id,
        "-f", "body=" .. body}, function()
      local nodes = entry.thread.comments.nodes
      nodes[#nodes + 1] = {author = {login = "you"}, body = body, createdAt = "just now"}
      local updated = thread_entry(entry.thread)
      entry.body, entry.replying, entry.reply = updated.body, false, nil
    end)
  end

  ttt.open_drawer({side = "left", width = 85, min_width = 30, render = function(p)
    p:hstack({height = 1, gap = 1, padding_right = 1, render = function(row)
      row:label({text = "Comments · PR #" .. pr.number, style = "bold", padding_left = 1})
      row:button({label = comments.expand_all and "Collapse all" or "Expand all", padding_left = 2, padding_right = 2,
        on_click = function() comments.expand_all = not comments.expand_all end})
      row:button({label = "Close", padding_left = 2, padding_right = 2, on_click = ttt.close_drawer})
    end})
    p:divider()
    if comments.pending > 0 then p:label({text = "Loading comments…", style = "muted", padding_left = 1}) end
    if #comments.errors > 0 then
      p:label({text = table.concat(comments.errors, "\n"), style = "danger", padding_left = 1})
    end
    if #comments.entries == 0 and comments.pending == 0 then
      p:label({text = "No comments yet.", style = "muted", padding_left = 1})
    end
    p:scrollview({render = function(list)
      for _, entry in ipairs(comments.entries) do
        local t = entry.thread
        local open = comments.expand_all or (t ~= nil and not t.isResolved)
        list:markdown({text = entry_markdown(entry, open), padding_left = 1, padding_right = 1})
        if t and not t.isResolved then
          if entry.replying then
            list:box({border = true, padding_left = 1, padding_right = 1, margin_left = 1, margin_right = 1,
              render = function(box)
                box:input({placeholder = "Write a reply…", multiline = true, min_rows = 3, max_rows = 6,
                  autofocus = true, value = entry.reply or "",
                  on_change = function(text) entry.reply = text end})
              end})
          end
          list:hstack({height = 1, gap = 1, padding_right = 1, render = function(row)
            row:label(t.busy and {text = "Working…", style = "muted", padding_left = 1} or "")
            if t.busy then return end
            if entry.replying then
              row:button({label = "Cancel", padding_left = 2, padding_right = 2,
                on_click = function() entry.replying, entry.reply = false, nil end})
              row:button({label = "Send", padding_left = 2, padding_right = 2, on_click = function() send_reply(entry) end})
            else
              if t.viewerCanReply then
                row:button({label = "Reply", padding_left = 2, padding_right = 2,
                  on_click = function() entry.replying = true end})
              end
              if t.viewerCanResolve then
                row:button({label = "Resolve", padding_left = 2, padding_right = 2, on_click = function() resolve(entry) end})
              end
            end
          end})
        end
        list:divider()
      end
    end})
  end})

  local base = "repos/" .. pr.repo
  for _, source in ipairs({
    {path = base .. "/issues/" .. pr.number .. "/comments", time = "created_at"},
    {path = base .. "/pulls/" .. pr.number .. "/reviews", time = "submitted_at"},
  }) do
    gh({"api", "--paginate", source.path, "--jq", ".[] | @json"}, nil, function(text, err)
      comments.pending = comments.pending - 1
      if err then comments.errors[#comments.errors + 1] = tostring(err); return end
      for line in text:gmatch("[^\r\n]+") do
        local c, parse_err = decode(line)
        if not c then comments.errors[#comments.errors + 1] = parse_err; break end
        if type(c.body) == "string" and c.body:match("%S") then
          local author = c.user and c.user.login or "ghost"
          comments.entries[#comments.entries + 1] = {time = c[source.time] or "", tag = "Comment",
            summary = "@" .. author .. ": " .. summary_text(c.body),
            body = comment_block(author, c[source.time], c.body)}
        end
      end
      sort_entries()
    end)
  end
  local owner, name = pr.repo:match("^([^/]+)/(.+)$")
  gh({"api", "graphql", "--paginate", "-f", "query=" .. THREADS_QUERY, "-f", "owner=" .. owner, "-f", "name=" .. name,
      "-F", "number=" .. pr.number, "--jq", ".data.repository.pullRequest.reviewThreads.nodes[] | @json"}, nil,
      function(text, err)
    comments.pending = comments.pending - 1
    if err then comments.errors[#comments.errors + 1] = "Threads: " .. tostring(err); return end
    for line in text:gmatch("[^\r\n]+") do
      local t, parse_err = decode(line)
      if not t then comments.errors[#comments.errors + 1] = parse_err; break end
      comments.entries[#comments.entries + 1] = thread_entry(t)
    end
    sort_entries()
  end)
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
		icon = { plain = "⑂", nerd = "\238\169\164" },
    render = function(p)
      sidebar = p
      p:hstack({height = 1, gap = 1, render = function(row)
        row:input({value = state.url, placeholder = "https://github.com/owner/repo...", autofocus = true,
          on_change = function(text) state.url = text end,
          on_submit = function() load_prs() end})
        row:button({label = "Load", padding_left = 2, padding_right = 2, on_click = function() load_prs() end})
      end})
      p:divider()
      -- Same height as the PR section below, so the list doesn't jump while a PR loads.
      if state.opening then
        p:box({height = 3, render = function(box)
          box:label({text = "Loading PR #" .. state.opening .. "…", style = "muted", padding_left = 1})
        end})
        p:divider()
      elseif not state.current then
        p:box({height = 3, render = function() end})
        p:divider()
      else
        p:hstack({height = 1, gap = 1, padding_bottom = 1, render = function(row)
          row:label({text = "#" .. state.current.number .. " " .. state.current.title, style = "muted", padding_left = 1})
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
          row:button({label = "Comments (" .. state.current.comments .. ")", padding_left = 2, padding_right = 2,
            on_click = open_comments})
          row:button({label = "Review", padding_left = 2, padding_right = 2, on_click = open_review})
        end})
        p:divider()
      end
      if state.repo == "" then
        p:box({height = 2, render = function() end})
      else
        local heading = state.single and "Pull request" or
            (state.pr_state == "closed" and "Closed pull requests" or "Open pull requests")
        local count = state.loading and "…" or (#state.prs >= 100 and "100+" or tostring(#state.prs))
        p:hstack({height = 1, gap = 1, render = function(row)
          row:label({text = heading, style = "muted", padding_left = 1})
          row:box({width = ttt_text.width(count), render = function(box)
            box:label({text = count, style = "muted"})
          end})
          row:dropdown({label = "⋮", entries = {
            {label = "Open", command = "open", checked = state.pr_state == "open"},
            {label = "Closed", command = "closed", checked = state.pr_state == "closed"},
          }, on_menu = switch_pr_state})
        end})
        p:divider()
      end
      p:vstack({padding_left = 1, padding_right = 1, render = function(list)
        if state.error ~= "" then list:label({text = state.error, style = "danger"}) end
        local items = {}
        for _, pr in ipairs(state.prs) do
          local badge = pr.isDraft and "draft" or ""
          if pr.state == "MERGED" then badge = "merged" elseif pr.state == "CLOSED" then badge = "closed" end
          items[#items + 1] = {id = tostring(pr.number), label = "#" .. pr.number .. " " .. pr.title,
            badge = badge, muted = pr.isDraft}
        end
        local active = state.opening or (state.current and state.current.number)
        list:list({items = items, badge_right = true, active = active and tostring(active), on_command = function(command, node)
          if command == "activate" then open_pr(tonumber(node.id)) end
        end})
      end})
      if #state.saved > 0 then
        p:divider()
        p:label({text = "Saved repositories", style = "muted", padding_left = 1, padding_right = 1})
        local items, active = {}, nil
        for _, url in ipairs(state.saved) do
          items[#items + 1] = {id = url, label = repository(url)}
          if state.repo ~= "" and repository(url):lower() == state.repo:lower() then active = url end
        end
        p:box({height = 7, padding_left = 1, padding_right = 1, render = function(favorites)
          favorites:list({items = items, active = active, on_command = function(command, node)
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
    {id = "pr-review.load", title = "PR Review: Load", handler = function() load_prs() end},
    {id = "pr-review.review", title = "PR Review: Review", handler = open_review},
    {id = "pr-review.comments", title = "PR Review: Comments", handler = open_comments},
  },
})
