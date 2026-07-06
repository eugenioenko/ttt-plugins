-- spell-demo: a small, self-contained example of the ttt plugin diagnostics +
-- editor context-menu API. A tiny built-in dictionary stands in for a real
-- checker (no aspell), so it flags only a handful of words — the point is to
-- show the API pattern, not to be a complete spell checker.

local editor = require("ttt.editor")
local diag = require("ttt.diagnostics")
local events = require("ttt.events")

-- misspelling -> correction
local DICT = {
  teh = "the",
  recieve = "receive",
  adn = "and",
  wrok = "work",
  mispell = "misspell",
  langauge = "language",
  seperate = "separate",
}

-- Iterate alphabetic words, calling fn(startCol, endCol, word) in RUNE columns
-- (endCol exclusive) so squiggles line up on non-ASCII lines too. Lua's
-- string.find returns BYTE offsets; editor.byte_to_col converts them to the
-- rune columns the diagnostics / replace APIs expect.
local function each_word(text, fn)
  local init = 1
  while true do
    local s, e, w = string.find(text, "(%a+)", init)
    if not s then break end
    fn(editor.byte_to_col(text, s), editor.byte_to_col(text, e + 1), w)
    init = e + 1
  end
end

local function scan()
  local path = editor.file_path()
  if path == nil or path == "" then return end
  local lines = editor.buffer_lines()
  local items = {}
  for i, text in ipairs(lines) do
    each_word(text, function(s, e, w)
      local corr = DICT[string.lower(w)]
      if corr then
        items[#items + 1] = {
          line = i,
          col = s,
          end_line = i,
          end_col = e, -- e is already the exclusive rune column
          severity = "warning",
          style = "danger", -- custom squiggle color (not the severity default)
          message = "Did you mean '" .. corr .. "'?",
          source = "spell-demo",
        }
      end
    end)
  end
  diag.publish(path, items)
end

-- Right-click on a flagged word -> offer the correction.
editor.register_context_menu(function(line, col, word)
  if word == nil or word == "" then return {} end
  local corr = DICT[string.lower(word)]
  if corr == nil then return {} end

  local lines = editor.buffer_lines()
  local text = lines[line] or ""
  local result = {}
  each_word(text, function(s, e, w)
    if col >= s and col < e and string.lower(w) == string.lower(word) then
      result = {
        { label = "Correct to '" .. corr .. "'", on_select = function()
          editor.replace(line, s, line, e, corr)
          scan()
        end },
        { separator = true },
        { label = "spell-demo: ignore" },
      }
    end
  end)
  return result
end)

events.on("editor.change", scan)
events.on("file.open", scan)
events.on("tab.change", scan)
scan()
