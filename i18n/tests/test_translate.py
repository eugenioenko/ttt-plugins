import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from translate import check_translation, load_locales, read_messages, source_hash, update_locale, validate


class IncrementalTranslationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "i18n").mkdir()
        self.locale = {"locale": "es", "name": "Español", "language": "Spanish"}
        self.calls = []

    def translate(self, batch, locale, context):
        self.calls.append(dict(batch))
        return {key: "ES " + text for key, text in batch.items()}

    def test_only_added_and_changed_english_values_are_sent(self):
        source = {"general.save": "Save", "status.saved": "Saved {filename}"}
        self.assertEqual(update_locale(self.root, self.locale, source, self.translate), 2)
        directory = self.root / "ttt-i18n-es"
        messages_file, hashes_file = directory / "messages.json", directory / "source-hashes.json"
        messages = read_messages(messages_file)
        messages["general.save"] = "Manually polished translation"
        messages_file.write_text(json.dumps(messages, ensure_ascii=False, indent=4))
        unchanged = {p: p.read_bytes() for p in directory.iterdir()}
        self.calls.clear()
        self.assertEqual(update_locale(self.root, self.locale, source, self.translate), 0)
        self.assertEqual(self.calls, [])
        self.assertEqual(unchanged, {p: p.read_bytes() for p in directory.iterdir()})
        source["status.saved"] = "Saved file {filename}"
        source["general.cancel"] = "Cancel"
        update_locale(self.root, self.locale, source, self.translate)
        self.assertEqual(self.calls, [{"general.cancel": "Cancel", "status.saved": "Saved file {filename}"}])
        self.assertEqual(read_messages(messages_file)["general.save"], "Manually polished translation")
        self.assertEqual(read_messages(hashes_file)["status.saved"], source_hash(source["status.saved"]))
        validate(self.root, [self.locale], source)

    def test_release_metadata_updates_without_translating_unchanged_keys(self):
        source = {"general.save": "Save"}
        update_locale(self.root, self.locale, source, self.translate)
        directory = self.root / "ttt-i18n-es"
        before = (directory / "messages.json").read_bytes()
        (self.root / "i18n" / "source").mkdir()
        (self.root / "i18n" / "source" / "upstream.json").write_text(' {"tttVersion":"1.12.0"}')
        self.calls.clear()
        update_locale(self.root, self.locale, source, self.translate)
        self.assertEqual(self.calls, [])
        self.assertEqual(before, (directory / "messages.json").read_bytes())
        self.assertEqual(json.loads((directory / "plugin.ttt.json").read_text())["languages"][0]["tttVersion"], "1.12.0")

    def test_deleted_keys_are_pruned_without_llm(self):
        source = {"general.save": "Save", "general.old": "Old"}
        update_locale(self.root, self.locale, source, self.translate)
        self.calls.clear()
        del source["general.old"]
        update_locale(self.root, self.locale, source, self.translate)
        self.assertEqual(self.calls, [])
        validate(self.root, [self.locale], source)

    def test_invalid_response_does_not_advance_source_hash(self):
        source = {"general.save": "Save"}
        update_locale(self.root, self.locale, source, self.translate)
        source["general.save"] = "Save {filename}"
        directory = self.root / "ttt-i18n-es"
        before = {p: p.read_bytes() for p in directory.iterdir()}
        with self.assertRaises(ValueError):
            update_locale(self.root, self.locale, source, lambda *args: {"general.save": "Missing placeholder"})
        self.assertEqual(before, {p: p.read_bytes() for p in directory.iterdir()})

    def test_resume_keeps_completed_batches_untouched(self):
        source = {"general.a": "A", "general.b": "B"}
        def fail_second(batch, locale, context):
            if "general.b" in batch:
                raise RuntimeError("interrupted")
            return self.translate(batch, locale, context)
        with self.assertRaises(RuntimeError):
            update_locale(self.root, self.locale, source, fail_second, batch_size=1)
        self.calls.clear()
        update_locale(self.root, self.locale, source, self.translate, batch_size=1)
        self.assertEqual(self.calls, [{"general.b": "B"}])

    def test_unchanged_but_invalid_manual_translation_is_not_regenerated(self):
        source = {"status.saved": "Saved {filename}"}
        update_locale(self.root, self.locale, source, self.translate)
        messages_file = self.root / "ttt-i18n-es" / "messages.json"
        messages_file.write_text('{"status.saved":"incorrect manual edit"}')
        self.calls.clear()
        with self.assertRaises(ValueError):
            update_locale(self.root, self.locale, source, self.translate)
        self.assertEqual(self.calls, [])

    def test_placeholder_counts_and_literals(self):
        check_translation("status.test", "{name} {name}: 50%", "50%: {name} {name}")
        for invalid in ["{name}", "{other} {other}", "{name} {name} {bad", ""]:
            with self.assertRaises(ValueError):
                check_translation("status.test", "{name} {name}: 50%", invalid)

    def test_duplicate_json_keys_are_rejected(self):
        path = self.root / "messages.json"
        path.write_text('{"general.save":"one","general.save":"two"}')
        with self.assertRaises(ValueError):
            read_messages(path)

    def test_duplicate_and_escaping_locales_are_rejected(self):
        file = self.root / "i18n" / "languages.json"
        for locales in [[self.locale, self.locale], [dict(self.locale, locale="../es")], {}]:
            file.write_text(json.dumps(locales))
            with self.assertRaises(ValueError):
                load_locales(self.root)


if __name__ == "__main__":
    unittest.main()
