# Language pack maintenance

This directory maintains translations for TTT, a terminal code editor. Use developer terminology appropriate to Git, LSP, files, commands, settings, and code editing.

- Generate through `python3 i18n/scripts/translate.py`, using the locally installed Codex CLI.
- Only added or changed English keys may be sent for translation. Never regenerate unchanged translations or overwrite manual corrections as cleanup.
- Source hashes represent English UTF-8 values, not translated text. Update a hash only after its translation succeeds.
- Preserve flat message keys, exact named placeholders and occurrence counts, meaningful whitespace, and technical identifiers. Icons belong in TTT's icon definitions.
- Sync an upstream release ref before publishing catalogs for that release. Unreleased snapshots use `tttVersion: "dev"`; do not claim compatibility with an unverified release.
- Language packs are declarative JSON plugins with no Lua entry point or permissions. Keep plugin versions separate from target TTT versions.
- Run `python3 -m unittest discover -s i18n/tests` and `python3 i18n/scripts/translate.py validate`. Regenerate registry entries with `python3 i18n/scripts/translate.py registry` after adding packs.

Run commands from the repository root. Language plugin folders and manifest names must share the `ttt-i18n-` prefix, with lowercase locale suffixes. Keep the root plugin index and the generated `i18n/community-plugins.json` entries consistent with those folders.
