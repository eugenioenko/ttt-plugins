PYTHON ?= python3
I18N_ARGS ?=

.PHONY: languages languages-check

languages-check:
	$(PYTHON) -m unittest discover -s i18n/tests
	$(PYTHON) i18n/scripts/translate.py validate

languages:
	$(PYTHON) i18n/scripts/translate.py generate $(I18N_ARGS)
	$(PYTHON) i18n/scripts/translate.py registry
