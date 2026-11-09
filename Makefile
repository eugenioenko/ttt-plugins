PYTHON ?= python3
I18N_REF ?= main
I18N_ARGS ?=

.PHONY: download translate languages languages-check

languages-check:
	$(PYTHON) -m unittest discover -s i18n/tests
	$(PYTHON) i18n/scripts/translate.py validate
	$(PYTHON) i18n/scripts/translate.py audit-length

download:
	$(PYTHON) i18n/scripts/translate.py sync --ref $(I18N_REF)

translate languages:
	$(PYTHON) i18n/scripts/translate.py generate --jobs 5 $(I18N_ARGS)
	$(PYTHON) i18n/scripts/translate.py registry
