# Working on ttt plugins

Use the maintained documentation in the [ttt host repository](https://github.com/eugenioenko/ttt):

- [Plugin authoring and API reference](https://github.com/eugenioenko/ttt/blob/main/docs-web/src/content/docs/guides/plugin-authoring.md)
- [Testing plugins](https://github.com/eugenioenko/ttt/blob/main/docs-web/src/content/docs/guides/plugin-testing.md)
- [Installing and managing plugins](https://github.com/eugenioenko/ttt/blob/main/docs-web/src/content/docs/guides/plugins.md)

Read the documentation for the host version being tested before changing API usage. Use a local host checkout when available; inspect its implementation when behavior remains unclear. Keep API details and examples in the host documentation rather than duplicating them here.

## Implementation

- Keep changes scoped and preserve public identifiers unless a migration is intended.
- Follow documented APIs, lifecycle, and permission scopes. Request only the access the plugin needs.
- Keep rendering repeatable and external work responsive. Handle stale async results and failures.
- Use host widgets, styles, and layout conventions; preserve keyboard, mouse, and Unicode behavior.
- Keep the plugin README and manifest consistent with its behavior.

## Verification

- Use the host's testing guide and isolated configuration. Choose the smallest deterministic check that proves the changed behavior.
- Check affected loading, empty, and error states. Include visible evidence for UI changes.
- Explain the behavior and actual verification in the PR. Prioritize actionable correctness and UX findings over cosmetic suggestions.
