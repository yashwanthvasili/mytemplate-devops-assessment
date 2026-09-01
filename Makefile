.PHONY: help env deps setup browser-install browser-install-ci clean clean-reports \
	prepare-reports lint security test test-backend test-ui reports check ci \
	agent-setup agent-resetdb agent-smoke agent-test

PYTHON ?= python3
VENV ?= env
VENV_PYTHON=$(VENV)/bin/python
VENV_RUFF=$(VENV)/bin/ruff
VENV_BANDIT=$(VENV)/bin/bandit
VENV_PLAYWRIGHT=$(VENV)/bin/playwright
REPORT_DIR=reports
TEST_ENV=APPNAME_ENV=test
PYTEST=$(VENV_PYTHON) -m pytest

help:
	@echo "  setup              create the environment, install dev tools, and install Chromium"
	@echo "  deps               install application and QA dependencies"
	@echo "  browser-install    install the local Chromium browser"
	@echo "  browser-install-ci install Chromium and Linux dependencies in CI"
	@echo "  lint               run Ruff and write reports/ruff.json"
	@echo "  security           run Bandit and write reports/bandit.json"
	@echo "  test-backend       run backend tests with JUnit and coverage reports"
	@echo "  test-ui            run the Chromium UI test with failure artifacts"
	@echo "  reports            run every quality check and generate all reports"
	@echo "  check              alias for the complete reports pipeline"
	@echo "  ci                 CI entry point; alias for check"
	@echo "  clean-reports      remove generated reports but preserve reports/README.md"

$(VENV_PYTHON):
	$(PYTHON) -m venv $(VENV)

env: $(VENV_PYTHON)

deps: env
	$(VENV_PYTHON) -m pip install --upgrade pip
	$(VENV_PYTHON) -m pip install -r requirements-dev.txt

setup: deps browser-install

browser-install: deps
	$(VENV_PLAYWRIGHT) install chromium

browser-install-ci: deps
	$(VENV_PLAYWRIGHT) install --with-deps chromium

prepare-reports:
	mkdir -p $(REPORT_DIR)

lint: prepare-reports
	$(VENV_RUFF) check . --output-format=json --output-file $(REPORT_DIR)/ruff.json

security: prepare-reports
	$(VENV_BANDIT) -r appname -f json -o $(REPORT_DIR)/bandit.json

test: test-backend

test-backend: prepare-reports
	$(TEST_ENV) $(PYTEST) tests/ \
		--ignore=tests/test_ui_signup.py \
		--junitxml=$(REPORT_DIR)/pytest.xml \
		--cov=appname \
		--cov-report=term-missing \
		--cov-report=xml:$(REPORT_DIR)/coverage.xml \
		--cov-report=html:$(REPORT_DIR)/coverage-html

test-ui: prepare-reports
	$(TEST_ENV) $(PYTEST) tests/test_ui_signup.py \
		--browser chromium \
		--tracing retain-on-failure \
		--screenshot only-on-failure \
		--output $(REPORT_DIR)/playwright \
		--junitxml=$(REPORT_DIR)/playwright.xml

reports: lint security test-backend test-ui

check: reports

ci: check

clean-reports:
	@test "$(REPORT_DIR)" = "reports"
	find $(REPORT_DIR) -depth -mindepth 1 ! -path '$(REPORT_DIR)/README.md' -delete

clean: clean-reports
	find appname tests -type f \( -name '*.pyc' -o -name '*.pyo' \) -delete
	find appname tests -type d -name '__pycache__' -prune -exec rm -rf {} +

agent-setup: setup

agent-resetdb:
	@if [ ! -x "$(VENV_PYTHON)" ]; then echo "Run 'make setup' first."; exit 1; fi
	APPNAME_ENV=dev $(VENV_PYTHON) manage.py resetdb

agent-smoke:
	@if [ ! -x "$(VENV_PYTHON)" ]; then echo "Run 'make setup' first."; exit 1; fi
	$(TEST_ENV) $(PYTEST) -q tests/test_urls.py tests/test_login.py

agent-test: test-backend
