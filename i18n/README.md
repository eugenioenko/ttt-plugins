# Language packs in ttt-plugins

Interface translations for the [TTT terminal code editor](https://github.com/eugenioenko/ttt), generated locally with the installed [Codex CLI](https://developers.openai.com/codex/cli/). These are machine-generated translations; corrections from native speakers are welcome.

The collection covers Arabic, Bengali, Czech, Danish, German, Greek, Spanish, Persian, Finnish, French, Hebrew, Hindi, Hungarian, Indonesian, Italian, Japanese, Korean, Norwegian Bokmål, Dutch, Polish, Brazilian Portuguese, Romanian, Russian, Slovenian, Swedish, Thai, Turkish, Ukrainian, Vietnamese, Simplified Chinese, and Traditional Chinese. English ships with TTT. Terminal support for bidirectional text and shaping affects Arabic, Hebrew, and Persian display.

After this pack PR merges and the corresponding entries reach the [host main registry](https://github.com/eugenioenko/ttt/blob/main/community-plugins.json), install a pack from TTT's Plugins panel, choose **Change Display Language** (or **Settings → General → Display language**), and restart. Packs require TTT 1.12.0 or later. The editor caches them for offline use. Its default-on **Update languages on upgrade** setting checks for a compatible catalog when a newer TTT version starts.

The generated `i18n/community-plugins.json` is a registry export for maintainers; TTT reads the host repository's registry. Merge pack files here before registering them in the host. Every future language pack also needs a host registry entry.

For TTT 1.12.0 or later before a pack is listed, use [manual installation](https://github.com/eugenioenko/ttt/blob/main/docs-web/src/content/docs/guides/plugins.md#manual-installation):

1. Copy the chosen `ttt-i18n-*` folder into the TTT configuration directory's `plugins/` folder.
2. Read `languages[0].sourceCommit` from its manifest. Download `https://raw.githubusercontent.com/eugenioenko/ttt/<sourceCommit>/internal/i18n/en.json` to `languages/sources/<sourceCommit>.json` under the same configuration directory. Create that directory if needed; languages referencing the same commit share this file.
3. Restart TTT, approve the plugin, choose its display language, and restart to apply it.

The default configuration directory is `~/.config/ttt` on Linux; `TTT_CONFIG_DIR` can override it. The English source download is handled automatically for normal installation through the Plugins panel.

Run the following commands from the `ttt-plugins` repository root. Plugin directories and manifest names share the `ttt-i18n-` prefix (for example, `ttt-i18n-es` and `ttt-i18n-pt-br`); locale tags retain their canonical casing inside the manifest.

## Generate locally

Requires Python 3.10+ on Linux/macOS, an installed `codex` executable, and an authenticated local Codex CLI. Generation uses your CLI configuration and saved login. Credentials are never stored here. CI only validates committed catalogs; it never calls an LLM.

```sh
# Fetch the latest English catalog from TTT main.
make download

# Inspect the number of added/changed keys per locale.
python3 i18n/scripts/translate.py plan

# Generate every language using the local Codex CLI (5 concurrent jobs).
make translate

# Or select languages and an executable explicitly.
make translate I18N_ARGS='--locale es --locale ja --codex /path/to/codex'

make languages-check
```

To download and translate without running the separate test/check target, run `make download && make translate`. `make download` fetches TTT `main` by default; `I18N_REF` selects another upstream ref. `make translate` generates all locales and refreshes `i18n/community-plugins.json`; `make languages` remains an alias. `I18N_ARGS` passes options to generation; selected-locale runs still require every pack to validate before exporting the full registry. `make languages-check` runs the unit tests and validates all packs without calling an LLM. `PYTHON` can select another Python executable. Plain `make` defaults to validation.

For a release, use `make download I18N_REF=vX.Y.Z` with a published TTT tag that includes `internal/i18n/en.json`. Releases predating the English catalog cannot be used for sync. Downloading `main` prepares unreleased translations with `tttVersion: "dev"`; the release updater ignores those until a compatible release target is published. The script's `sync --ttt-version X.Y.Z` explicitly sets the target when syncing another ref. `i18n/source/upstream.json` records the source commit and target TTT version. Publishing a new target with unchanged English text updates manifest metadata without translation calls.

The prompt identifies TTT as a **code editor**, with developer terminology for Git staging, branches, diffs, LSP diagnostics, code folding, commands, and settings. It requests compact UI text close to the English width, supplies per-key length review bounds and existing translations for consistency, and preserves named placeholders and technical identifiers. Long literal translations should be rephrased with familiar developer terms instead of expanding acronyms or explaining short labels. Settings labels should aim to fit 30 terminal columns where meaning permits. Action, scope, negation, and essential warnings take priority over brevity. Codex runs with a read-only sandbox in a temporary directory and returns JSON matching an exact-key schema. `--model` optionally overrides the locally configured model. `--batch-size` controls request size; `--jobs` controls concurrent locales. `make translate` defaults to 5 jobs; override with, for example, `make translate I18N_ARGS='--jobs 3'`.

### Review long translations

Generation and `make languages-check` (including CI) print an advisory length audit. Run it separately for all packs or selected locales:

```sh
python3 i18n/scripts/translate.py audit-length
python3 i18n/scripts/translate.py audit-length --locale it --locale es
```

The audit lists the locale, key, English and translated text, widths, and review bound. It flags copy only when its widest literal line exceeds **both 2.5× the English width and 12 extra columns** (the ratio bound is rounded down). Named placeholders are excluded from both widths so long variable names cannot hide expanded copy. Wide/fullwidth characters count as two columns; other code points, including combining marks, count as one to approximate TTT's rune-based grid. This is a conservative review heuristic; terminal width settings and actual substituted values can change the rendered width. It does not guarantee that every unflagged label fits.

Normal expansion is expected. Review candidates in context, shorten extreme cases manually in the relevant `messages.json`, and check related menu/command/settings labels for consistent terminology. Prefer concise natural phrases and established developer terms; remove redundant explanations before considering familiar abbreviations. Never mechanically truncate words, remove placeholders, or sacrifice action, scope, negation, or essential warning information. Inspect affected screens with the [host test harness](https://github.com/eugenioenko/ttt/blob/main/docs-web/src/content/docs/guides/plugin-testing.md) and an isolated `TTT_CONFIG_DIR`.

Length findings do not fail tests or validation, trigger retries, or cause unchanged keys to be regenerated. Error messages and explanatory text can stay long when the detail is useful. A necessary long translation can remain after review. The audit itself never changes catalogs. Manual corrections stay intact while English is unchanged, just like other translation improvements.

## Incremental behavior

`i18n/source/en.json` is the current English catalog. The single shared `i18n/source/snapshot.json` records the English values from the last complete generation. The script compares dictionary values, independently of JSON formatting or order. Only added/changed English keys and missing translations are sent to Codex. Manual translation improvements stay untouched while English remains unchanged. Deleted source keys are pruned without an LLM call. A no-op makes no LLM calls and leaves existing translation bytes unchanged.

After all configured languages finish and validate, generation advances the shared snapshot. Selected-locale runs leave it unchanged. Interrupted runs may repeat translations for English keys still different from the shared snapshot; there is no per-language hash or progress database. Every response must contain exactly the requested keys and preserve placeholders. Invalid responses are retried up to three times. A repository lock prevents overlapping source updates and generation.

### Preserve selected translations

Skip keys for the selected locales with a one-off CLI option:

```sh
make translate I18N_ARGS='--locale es --ignore-keys general.save,menu.file'
```

`--ignore-keys` accepts comma-separated IDs and can be repeated. Without `--locale`, it applies to every configured language. Permanent exceptions live in `i18n/ignored-keys.json`:

```json
{
  "es": ["general.save"],
  "fr": ["menu.file"]
}
```

Ignored keys preserve their existing translations even after English changes. They must already exist and still pass placeholder validation; fix an incompatible manual translation rather than sending it to the LLM. Unknown locales or message IDs in ignore rules are errors. Ignoring a key intentionally approves that existing translation against the new English source. Removing an ignore rule does not regenerate the key until English changes again.

### Runtime freshness

Each manifest references the TTT English source commit through `languages[].sourceCommit`. The host downloads that commit's `internal/i18n/en.json` during installation or update and shares one cached English catalog across languages using that commit. It compares English values directly to detect stale messages, including when offline. There is no English snapshot or hash map copied into each plugin folder.

## Layout

- `i18n/source/en.json`: upstream English messages, the only translation source.
- `i18n/source/snapshot.json`: shared English baseline from the last complete generation.
- `i18n/ignored-keys.json`: permanent per-language exceptions.
- `i18n/source/upstream.json`: source commit and target TTT release.
- `i18n/languages.json`: supported locales and native names; add a locale here before generating it.
- `ttt-i18n-<locale-lowercase>/messages.json`: flat `area.name` translation dictionary.
- `ttt-i18n-<locale-lowercase>/plugin.ttt.json`: declarative plugin, no Lua or permissions.
- `i18n/community-plugins.json`: registry entries for all validated packs.

The plugin `version` describes the pack itself; `languages[].tttVersion` describes the TTT release covered by its catalog. Update the latter through source sync and generation. A stale or missing message falls back to TTT's embedded English text. Core catalogs do not translate copy owned by other Lua plugins.

For translation corrections, edit only the relevant `messages.json` values and run validation. Preserve keys, named placeholders (such as `{filename}`), their occurrence counts, meaningful whitespace, and technical identifiers. Keep icons in TTT's icon definitions. Use ignore rules to explicitly preserve translations across English changes.
