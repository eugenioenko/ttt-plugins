import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from translate import (check_translation, generate, load_ignored_keys, load_locales,
                       pending_keys, read_messages, translation_context, write_json)


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


if __name__ == "__main__":
    unittest.main()
