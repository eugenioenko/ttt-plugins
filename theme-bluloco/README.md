# Bluloco Theme

[Bluloco](https://github.com/uloco/bluloco.nvim) dark and light, ported from Umut Topuzoğlu's Neovim theme ([uloco/bluloco.nvim](https://github.com/uloco/bluloco.nvim) at `bc0e042`, `lua/lush_theme/bluloco.lua`), packaged as a theme plugin.

- Syntax colors follow the Neovim highlight groups: keywords, functions, types, strings, numbers, constants, properties, parameters, modules, tags, and attributes use the same palette entries.
- Editor, status bar, tab, float, diff, and search colors come from the same file. Derived shades (cursor line, status bar, borders, scrollbar) are computed with lush.nvim's lighten and mix rules.
- Bracket pairs cycle through Bluloco's rainbow delimiter colors.
- The terminal palette follows the upstream kitty ports (`terminal-themes/kitty/BlulocoDark.conf`, `BlulocoLight.conf`). The dark terminal selection uses Bluloco's dark selection color (`#274670`) instead of kitty's, because ttt keeps the text color of selected terminal text.
- **bluloco-light-dark-terminal** is the light theme with the dark terminal palette, for a light editor beside a dark integrated terminal.

Requires ttt with manifest theme contributions (eugenioenko/ttt#1247).

Install **Bluloco Theme** from the Plugins panel, then choose **plugins/theme-bluloco/bluloco-dark**, **plugins/theme-bluloco/bluloco-light**, or **plugins/theme-bluloco/bluloco-light-dark-terminal** in **Switch Theme**. Installation does not change the active theme. No Lua code or permissions are needed.

Disabling the plugin keeps its themes available. Uninstalling removes them and returns to default colors if one was active.

Bluloco is distributed under the LGPL-3.0 license, Copyright (c) Umut Topuzoğlu.
