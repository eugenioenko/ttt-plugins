# Language pack maintenance

This directory maintains translations for TTT, a terminal code editor. Use developer terminology appropriate to Git, LSP, files, commands, settings, and code editing.

- Download the latest English catalog through `make download` (defaults to TTT `main`). Generate through `make translate` (`make languages` remains an alias), using the locally installed Codex CLI.
- Only added or changed English keys may be sent for translation. Never regenerate unchanged translations or overwrite manual corrections as cleanup.
- Compare English values against the one shared `i18n/source/snapshot.json`; advance it only after all configured languages validate. Selected-language and interrupted runs may repeat changed keys. Do not introduce per-language hash maps or progress databases.
- Respect `i18n/ignored-keys.json` and `--ignore-keys`. Ignored entries must already exist and pass placeholder validation. Pack manifests reference the TTT English `sourceCommit` for runtime freshness.
- Preserve flat message keys, exact named placeholders and occurrence counts, meaningful whitespace, and technical identifiers. Icons belong in TTT's icon definitions.
- Keep short UI copy compact. Review `audit-length` candidates and shorten extreme expansions manually using natural developer terminology; preserve action, scope, negation, and essential warnings. Error messages may stay long when the detail is useful. Length findings are advisory and must not fail tests or validation, truncate text, or regenerate unchanged translations. Check related labels for consistent vocabulary and verify affected screens in an isolated host configuration.
- Sync an upstream release ref before publishing catalogs for that release. Unreleased snapshots use `tttVersion: "dev"`; do not claim compatibility with an unverified release.
- Language packs are declarative JSON plugins with no Lua entry point or permissions. Keep plugin versions separate from target TTT versions.
- Run `make languages-check`. `make translate` also refreshes the registry; export it separately with `python3 i18n/scripts/translate.py registry` when needed.

Run commands from the repository root. Language plugin folders and manifest names must share the `ttt-i18n-` prefix, with lowercase locale suffixes. Keep the root plugin index and the generated `i18n/community-plugins.json` entries consistent with those folders.
