# Language packs in ttt-plugins

Interface translations for the [TTT terminal code editor](https://github.com/eugenioenko/ttt), generated locally with the installed [Codex CLI](https://developers.openai.com/codex/cli/). These are machine-generated translations; corrections from native speakers are welcome.

The initial collection covers Arabic, Bengali, Czech, Danish, German, Greek, Spanish, Persian, Finnish, French, Hebrew, Hindi, Hungarian, Indonesian, Italian, Japanese, Korean, Norwegian Bokmål, Dutch, Polish, Brazilian Portuguese, Romanian, Russian, Swedish, Thai, Turkish, Ukrainian, Vietnamese, Simplified Chinese, and Traditional Chinese. English ships with TTT. Terminal support for bidirectional text and shaping affects Arabic, Hebrew, and Persian display.

Install a pack from TTT's Plugins panel, choose **Change Display Language** (or **Settings → General → Display language**), and restart. Packs require a TTT build supporting `languages` manifest contributions. The editor caches them for offline use. Its default-on **Update languages on upgrade** setting checks for a compatible catalog when a newer TTT version starts.

Run the following commands from the `ttt-plugins` repository root. Plugin directories and manifest names share the `ttt-i18n-` prefix (for example, `ttt-i18n-es` and `ttt-i18n-pt-br`); locale tags retain their canonical casing inside the manifest.

## Generate locally

Requires Python 3.10+ on Linux/macOS, an installed `codex` executable, and an authenticated local Codex CLI. Generation uses your CLI configuration and saved login. Credentials are never stored here. CI only validates committed catalogs; it never calls an LLM.

```sh
# Fetch the exact English catalog for a release, pinned to its commit.
python3 i18n/scripts/translate.py sync --ref v1.12.0

# Inspect the number of added/changed keys per locale.
python3 i18n/scripts/translate.py plan

# Generate every language using the local Codex CLI.
python3 i18n/scripts/translate.py generate --jobs 3

# Or select languages and an executable explicitly.
python3 i18n/scripts/translate.py generate --locale es --locale ja --codex /path/to/codex

python3 i18n/scripts/translate.py validate
python3 i18n/scripts/translate.py registry
python3 -m unittest discover -s i18n/tests
```

Use a release tag that exists in the TTT repository. `sync --ref main` prepares unreleased translations with `tttVersion: "dev"`; the release updater ignores those until a compatible release target is published. `--ttt-version X.Y.Z` explicitly sets the target when syncing another ref. `i18n/source/upstream.json` records the source commit and target TTT version. Publishing a new target with unchanged English text updates manifest metadata without translation calls.

The prompt identifies TTT as a **code editor**, with developer terminology for Git staging, branches, diffs, LSP diagnostics, code folding, commands, and settings. It requests concise UI text, preserves named placeholders and technical identifiers, and supplies existing common translations for consistency. Codex runs with a read-only sandbox in a temporary directory and returns JSON matching an exact-key schema. `--model` optionally overrides the locally configured model. `--batch-size` controls request size; `--jobs` controls concurrent locales.

## Incremental behavior

Each locale has its own `source-hashes.json`, containing the SHA-256 of each successfully translated English value. Only missing translations and keys whose English hash changed are sent to Codex. A manual translation correction stays untouched while its English source stays unchanged. Deleted source keys are pruned without an LLM call. A no-op generation makes no LLM calls and leaves existing catalog bytes unchanged.

Every response must contain exactly the requested keys and preserve placeholder names and occurrence counts. Invalid responses are retried up to three times without advancing source hashes. Successful batches are saved atomically and can be resumed after interruption. A repository lock prevents overlapping source updates and generation. An invalid manual edit to an unchanged key fails validation for human correction instead of silently requesting a new translation.

## Layout

- `i18n/source/en.json`: upstream English messages, the only translation source.
- `i18n/source/upstream.json`: source commit and target TTT release.
- `i18n/languages.json`: supported locales and native names; add a locale here before generating it.
- `ttt-i18n-<locale-lowercase>/messages.json`: flat `area.name` translation dictionary.
- `ttt-i18n-<locale-lowercase>/source-hashes.json`: per-message English source hashes.
- `ttt-i18n-<locale-lowercase>/plugin.ttt.json`: declarative plugin, no Lua or permissions.
- `i18n/community-plugins.json`: registry entries for all validated packs.

The plugin `version` describes the pack itself; `languages[].tttVersion` describes the TTT release covered by its catalog. Update the latter through source sync and generation. A stale or missing message falls back to TTT's embedded English text. Core catalogs do not translate copy owned by other Lua plugins.

For translation corrections, edit only the relevant `messages.json` values and run validation. Preserve keys, named placeholders (such as `{filename}`), their occurrence counts, meaningful whitespace, and technical identifiers. Keep icons in TTT's icon definitions. Do not edit a source hash to hide a changed English message.
