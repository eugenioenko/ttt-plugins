# Spell Demo

A small, self-contained example of ttt's **plugin diagnostics** and **editor
context-menu** APIs. It flags a handful of common misspellings from a tiny
built-in dictionary — there is no real spell-check backend (no aspell) — so it's
meant as a reference for building linter-style plugins, not a complete checker.

## What it demonstrates

- **`ttt.diagnostics.publish`** — draws curly-underline squiggles (with a custom
  colour) under flagged words, which also show in the **Diagnostics** panel.
- **`editor.register_context_menu`** — right-click a flagged word for a
  "Correct to '…'" fix.
- **`editor.byte_to_col`** — converts Lua's byte offsets from `string.find` into
  the rune columns the diagnostics/replace APIs expect (so squiggles line up on
  lines with multi-byte characters).
- Re-scanning on `editor.change` and `tab.change`.

## Usage

Open any file and type one of: `teh`, `recieve`, `adn`, `wrok`, `mispell`,
`langauge`, `seperate`. A squiggle appears; right-click it to fix.

## Requirements

Requires a ttt build that includes the plugin diagnostics API
(`ttt.diagnostics`, `editor.byte_to_col`) — i.e. a version newer than 0.3.5.
