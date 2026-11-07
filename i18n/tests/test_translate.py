import contextlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from translate import (audit_lengths, check_translation, codex_translate, copy_width, generate,
                       length_outliers, length_review_limit, load_ignored_keys, load_locales,
                       pending_keys, read_messages, translation_context, validate, write_json)


class TranslationTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.locale = {"locale": "es", "name": "Español", "language": "Spanish"}
        self.locales = [self.locale]
        self.calls = []
        self.snapshot = self.root / "i18n/source/snapshot.json"
        self.metadata = self.root / "i18n/source/upstream.json"
        write_json(self.metadata, {"commit": "a" * 40, "tttVersion": "dev"})

    def translate(self, batch, locale, context):
        self.calls.append(dict(batch))
        return {key: "ES " + text for key, text in batch.items()}

    def run_generation(self, source, **options):
        generate(self.root, self.locales, self.locales, source, self.translate, **options)

    def messages_file(self):
        return self.root / "ttt-i18n-es/messages.json"

    def test_only_changed_english_values_and_missing_translations_are_sent(self):
        source = {"general.save": "Save", "status.saved": "Saved {filename}"}
        self.run_generation(source)
        messages = read_messages(self.messages_file())
        messages["general.save"] = "Manually polished translation"
        self.messages_file().write_text(json.dumps(messages, ensure_ascii=False, indent=4))
        before = self.messages_file().read_bytes()
        self.calls.clear()
        self.run_generation(source)
        self.assertEqual(self.calls, [])
        self.assertEqual(before, self.messages_file().read_bytes())
        source["status.saved"] = "Saved file {filename}"
        source["general.cancel"] = "Cancel"
        self.run_generation(source)
        self.assertEqual(self.calls, [{"general.cancel": "Cancel", "status.saved": "Saved file {filename}"}])
        self.assertEqual(read_messages(self.messages_file())["general.save"], "Manually polished translation")
        self.assertEqual(read_messages(self.snapshot), source)

    def test_diff_compares_values_instead_of_json_format_or_order(self):
        self.assertEqual(pending_keys({"a": "A", "b": "B"}, {"a": "AA", "b": "BB"}, {"b": "B", "a": "A"}), [])
        self.assertEqual(pending_keys({"a": "A"}, {}, {"a": "A"}), ["a"])

    def test_deleted_keys_are_pruned_without_llm(self):
        source = {"general.save": "Save", "general.old": "Old"}
        self.run_generation(source)
        self.calls.clear()
        del source["general.old"]
        self.run_generation(source)
        self.assertEqual(self.calls, [])
        self.assertEqual(read_messages(self.messages_file()), {"general.save": "ES Save"})

    def test_invalid_response_does_not_advance_snapshot_or_replace_messages(self):
        previous = {"general.save": "Save"}
        self.run_generation(previous)
        before = self.messages_file().read_bytes()
        with self.assertRaises(ValueError):
            generate(self.root, self.locales, self.locales, {"general.save": "Save {filename}"},
                     lambda *args: {"general.save": "Missing placeholder"})
        self.assertEqual(read_messages(self.snapshot), previous)
        self.assertEqual(self.messages_file().read_bytes(), before)

    def test_release_metadata_changes_without_llm(self):
        source = {"general.save": "Save"}
        self.run_generation(source)
        write_json(self.metadata, {"commit": "b" * 40, "tttVersion": "1.12.0"})
        self.calls.clear()
        self.run_generation(source)
        self.assertEqual(self.calls, [])
        manifest = json.loads((self.root / "ttt-i18n-es/plugin.ttt.json").read_text())
        self.assertEqual(manifest["languages"][0]["sourceCommit"], "b" * 40)
        self.assertEqual(manifest["languages"][0]["tttVersion"], "1.12.0")

    def test_ignored_changed_keys_preserve_existing_translation(self):
        self.run_generation({"general.save": "Save", "general.cancel": "Cancel"})
        messages = read_messages(self.messages_file())
        messages["general.save"] = "Polished Spanish"
        write_json(self.messages_file(), messages)
        self.calls.clear()
        self.run_generation({"general.save": "Save file", "general.cancel": "Cancel action"},
                            ignored={"es": {"general.save"}})
        self.assertEqual(self.calls, [{"general.cancel": "Cancel action"}])
        self.assertEqual(read_messages(self.messages_file())["general.save"], "Polished Spanish")
        self.calls.clear()
        self.run_generation({"general.save": "Save file", "general.cancel": "Cancel action"})
        self.assertEqual(self.calls, [])

    def test_ignored_keys_still_require_placeholders_and_existing_values(self):
        self.run_generation({"general.save": "Save"})
        self.calls.clear()
        for source in [{"general.save": "Save {filename}"}, {"general.cancel": "Cancel"}]:
            with self.assertRaises(ValueError):
                self.run_generation(source, ignored={"es": set(source)})
        self.assertEqual(self.calls, [])

    def test_unchanged_invalid_manual_edit_is_reported_without_llm(self):
        source = {"status.saved": "Saved {filename}"}
        self.run_generation(source)
        self.messages_file().write_text('{"status.saved":"incorrect edit"}')
        self.calls.clear()
        with self.assertRaises(ValueError):
            self.run_generation(source)
        self.assertEqual(self.calls, [])

    def test_ignore_file_and_cli_are_scoped_to_languages(self):
        locales = self.locales + [{"locale": "fr", "name": "Français", "language": "French"}]
        write_json(self.root / "i18n/ignored-keys.json", {"fr": ["general.cancel"]})
        rules = load_ignored_keys(self.root, locales, {"general.save": "Save", "general.cancel": "Cancel"},
                                 ["general.save"], {"es"})
        self.assertEqual(rules, {"es": {"general.save"}, "fr": {"general.cancel"}})
        for bad in [{"unknown": []}, {"es": ["unknown.key"]}, {"es": "general.save"}]:
            write_json(self.root / "i18n/ignored-keys.json", bad)
            with self.assertRaises(ValueError):
                load_ignored_keys(self.root, locales, {"general.save": "Save"})

    def test_new_language_translates_missing_keys_even_with_current_snapshot(self):
        write_json(self.snapshot, {"general.save": "Save"})
        self.run_generation({"general.save": "Save"})
        self.assertEqual(self.calls, [{"general.save": "Save"}])

    def test_selected_locale_does_not_advance_shared_snapshot(self):
        previous = {"general.save": "Save"}
        self.run_generation(previous)
        other = {"locale": "fr", "name": "Français", "language": "French"}
        generate(self.root, self.locales, self.locales + [other], {"general.save": "Save file"}, self.translate)
        self.assertEqual(read_messages(self.snapshot), previous)

    def test_context_uses_relevant_terms_across_prefixes_and_excludes_pending(self):
        source = {"git.stage": "Stage Git changes", "git.commit": "Commit Git changes",
                  "general.save": "Save file", "status.staged": "Git changes staged",
                  "git.future": "Future Git change"}
        messages = {"git.stage": "Preparar", "git.commit": "Confirmar",
                    "general.save": "Guardar", "git.future": "Old translation"}
        batch = {"status.staged": source["status.staged"]}
        context = translation_context(source, messages, ["status.staged", "git.future"], 0, batch, 2)
        self.assertEqual(set(context), {"git.stage", "git.commit"})
        self.assertNotIn("git.future", context)

    def test_placeholder_counts_and_literals(self):
        check_translation("status.test", "{name} {name}: 50%", "50%: {name} {name}")
        for invalid in ["{name}", "{other} {other}", "{name} {name} {bad", ""]:
            with self.assertRaises(ValueError):
                check_translation("status.test", "{name} {name}: 50%", invalid)

    def test_duplicate_keys_and_invalid_locales_are_rejected(self):
        file = self.root / "messages.json"
        file.write_text('{"general.save":"one","general.save":"two"}')
        with self.assertRaises(ValueError):
            read_messages(file)
        for locales in [[self.locale, self.locale], [dict(self.locale, locale="../es")], {}]:
            write_json(self.root / "i18n/languages.json", locales)
            with self.assertRaises(ValueError):
                load_locales(self.root)

    def test_length_review_requires_both_relative_and_absolute_expansion(self):
        source = {"short": "Save", "long": "x" * 20}
        # Even 4x expansion of a tiny label, or +20 on a longer line, is not extreme.
        self.assertEqual(length_outliers(source, {"short": "x" * 16, "long": "x" * 40}), [])
        self.assertEqual(length_outliers(source, {"short": "x" * 17, "long": "x" * 51}),
                         [("long", 20, 51, 50), ("short", 4, 17, 16)])
        self.assertEqual(length_review_limit("LSP Hover"), 22)

    def test_width_uses_widest_literal_line_and_terminal_columns(self):
        self.assertEqual(copy_width("Save {veryLongFilename}\n文件"), 5)
        self.assertEqual(copy_width("文件"), 4)
        self.assertEqual(copy_width("é"), 1)
        self.assertEqual(copy_width("e\u0301"), 2)  # TTT advances for each code point.
        self.assertEqual(copy_width(""), 0)
        source = {"a": "Save {veryLongFilename}"}
        self.assertEqual(length_outliers(source, {"a": "x" * 18 + " {veryLongFilename}"}),
                         [("a", 5, 19, 17)])

    def test_length_audit_is_advisory_and_does_not_rewrite_manual_copy(self):
        source = {"general.save": "Save"}
        self.run_generation(source)
        write_json(self.messages_file(), {"general.save": "Reviewed long translation that must stay"})
        before = self.messages_file().read_bytes()
        self.calls.clear()
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            self.assertEqual(audit_lengths(self.root, self.locales, source), 1)
            self.run_generation(source)
        self.assertIn("es general.save: 4 → 40 columns", output.getvalue())
        self.assertEqual(self.calls, [])
        self.assertEqual(self.messages_file().read_bytes(), before)
        self.assertEqual(read_messages(self.snapshot), source)

    def test_codex_receives_length_guidance_alongside_code_editor_context(self):
        batch = {"menu.lSPHover": "LSP Hover", "general.save": "Save {filename}"}

        def run(command, **options):
            prompt = options["input"]
            self.assertIn("terminal CODE EDITOR", prompt)
            self.assertIn("Git staging/commits/branches/diffs", prompt)
            self.assertIn("action, scope, negation, and essential warnings", prompt)
            payload = json.loads(prompt[prompt.index('{"target":'):])
            self.assertEqual(payload["length_review_columns"], {"menu.lSPHover": 22, "general.save": 17})
            self.assertEqual(payload["messages_to_translate"], batch)
            output = Path(command[command.index("--output-last-message") + 1])
            write_json(output, {"menu.lSPHover": "Ayuda LSP", "general.save": "Guardar {filename}"})
            return type("Result", (), {"returncode": 0})()

        with patch("translate.subprocess.run", side_effect=run):
            result = codex_translate(batch, self.locale, {})
        self.assertEqual(result["general.save"], "Guardar {filename}")

    def test_long_error_details_pass_validation_and_remain_unchanged(self):
        source = {"files.openFailed": "Could not open {path}: {error}"}
        self.run_generation(source)
        detailed = "No se pudo abrir {path}: {error}. " + "Información necesaria para resolver el problema. " * 8
        write_json(self.messages_file(), {"files.openFailed": detailed})
        before = self.messages_file().read_bytes()
        self.calls.clear()
        with contextlib.redirect_stdout(io.StringIO()):
            validate(self.root, self.locales, source)
            self.assertEqual(audit_lengths(self.root, self.locales, source), 1)
            self.run_generation(source)
        self.assertEqual(self.messages_file().read_bytes(), before)
        self.assertEqual(self.calls, [])


if __name__ == "__main__":
    unittest.main()
