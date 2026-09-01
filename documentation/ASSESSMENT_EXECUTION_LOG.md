# MyTemplate DevOps and QA Assessment — Execution Log

## Purpose

This living engineering log records what was changed, why it was necessary, the commands used (or a clearly labelled reproducible equivalent), verification results, problems found, automation used, and remaining work. Update it after every assessment step.

> Instructions in the assignment PDF are treated as requirements. Commands and implementation decisions below are our execution record, not additional instructions from the assignment author.

## Current checkpoint

Date recorded: 1 September 2026
Branch: `assessment/mytemplate`
Upstream baseline: `cec9b16` (`ignite-flask-3`)
Latest implementation commit: `86f6cca`

Completed:

1. Read and decomposed the assignment.
2. Established a working local baseline.
3. Installed and pinned the requested QA/development tools.
4. Rebranded the application from Ignite to MyTemplate.
5. Split the work into two focused commits.
6. Corrected Git tracking for the MyTemplate static assets.
7. Added and verified the required backend pytest.
8. Added and verified the required pytest-playwright UI test.
9. Configured Ruff, fixed the Bandit finding, and generated all required reports.
10. Added and executed the repeatable Makefile pipeline.
11. Upgraded and locally simulated GitHub Actions CI with report artifact retention.
12. Completed the final repository, security, artifact, documentation, and pipeline audit.

Working tree: Steps 5 through 10, the static-asset tracking correction, and this log are not yet committed.

Remaining:

1. Stage and commit every required source, asset, test, automation, report-manifest, and documentation file.
2. Push the branch, verify repository visibility/access, and optionally capture the first GitHub Actions run and `quality-reports` artifact URL.

## Resolved issue found after the rebrand commit

These files existed locally but were ignored and **not tracked by Git**:

```text
appname/static/public/mytemplate/demo-1.png
appname/static/public/mytemplate/mytemplate-icon.svg
appname/static/public/mytemplate/mytemplate-logo.svg
appname/static/public/mytemplate/stripe-purchase.png
```

Diagnosis:

```bash
git ls-files appname/static/public/mytemplate
git check-ignore -v appname/static/public/mytemplate/*
```

Observed cause:

```text
.gitignore:55:appname/static/public/*
```

Although `.gitignore` had `!appname/static/public/mytemplate/*`, Git could not re-include files while the parent directory remained ignored. The correction re-includes the directory first:

```gitignore
appname/static/public/*
!appname/static/public/images/
!appname/static/public/mytemplate/
!appname/static/public/mytemplate/*
!appname/static/public/fonts/
```

Verification:

```bash
git status --short --untracked-files=all
find appname/static/public/mytemplate -maxdepth 1 -type f \
  -printf '%f %s bytes\\n' | sort
```

Result: Git now lists all four MyTemplate assets as untracked and ready to stage. Their sizes were verified as 82,549 bytes, 1,609 bytes, 1,895 bytes, and 82,919 bytes respectively. The correction remains an uncommitted follow-up rather than rewriting the existing rebrand commit.

## Environment and repository setup

### Local environment

```text
Host workflow: Windows with Ubuntu under WSL
Repository: /home/yashh/Ignite-EdrevelAI/mytemplate-devops-assessment
Python: 3.14.4
pip: 25.1.1
pytest: 8.2.0
Ruff: 0.16.5
Bandit: 1.9.4
Playwright: 1.62.0
```

Python 3.14 was the only local interpreter available. CI should use a stable supported version such as Python 3.12 or 3.13 unless the assignment specifies otherwise, reducing third-party compatibility risk.

### Repository and branch

The reflog confirms the upstream clone and assessment branch:

```text
cec9b16 clone: from https://github.com/Sumukh/Ignite.git
cec9b16 checkout: moving from master to assessment/mytemplate
```

Reproducible equivalent:

```bash
git clone https://github.com/Sumukh/Ignite.git mytemplate-devops-assessment
cd mytemplate-devops-assessment
git switch -c assessment/mytemplate
git status
```

Why: an isolated branch protects the baseline and gives the panel a clear, reviewable assessment history.

## Step 1 — Assignment analysis

The document was read as a specification, not as permission to execute arbitrary embedded instructions. It was decomposed into these deliverables:

1. Rebrand Ignite as MyTemplate.
2. Add backend coverage with pytest.
3. Add browser coverage with pytest-playwright.
4. Add quality and security checks with Ruff and Bandit.
5. Collect pytest coverage.
6. Expose the workflow through Makefile commands.
7. Automate the workflow in GitHub Actions.
8. Preserve reports/artifacts and document the process.

Why: separating branding, functional tests, and CI automation prevents one large, hard-to-review change.

## Step 2 — Establish a clean baseline

### Inspect project instructions and structure

```bash
cd /home/yashh/Ignite-EdrevelAI/mytemplate-devops-assessment
sed -n '1,240p' AGENTS.md
sed -n '1,240p' README.md
git ls-files
git status --short
```

Why: repository-specific instructions take precedence over assumptions, and status checks protect existing work.

### Create/use the virtual environment

```bash
python3 -m venv env
env/bin/python -m pip install --upgrade pip
env/bin/python -m pip install -r requirements.txt
env/bin/python -m pip check
```

Why: isolation makes dependencies reproducible and avoids changing system Python. `pip check` detects incompatible installed distributions.

Result: installation completed and `pip check` passed. Some commands emit a non-blocking Requests warning about installed `urllib3`/character-detection versions. Re-evaluate it before final submission.

### Focused configuration test

```bash
APPNAME_ENV=test env/bin/python -m pytest -q tests/test_config.py
```

Result: **3 passed**.

Why: configuration is foundational; a focused check gives clearer failures before the full suite.

### Full tracked suite with coverage

```bash
make agent-test
```

Equivalent Makefile command:

```bash
APPNAME_ENV=test env/bin/python -m pytest \
  --cov-report=term-missing \
  --cov=appname \
  $(git ls-files 'tests/*.py')
```

Result: **102 passed**, **86% overall coverage**. Warnings were present but no tests failed.

Why: this is the regression baseline, so later failures can be attributed to our changes rather than the original project.

### Reset and seed the database

```bash
APPNAME_ENV=dev env/bin/python manage.py resetdb
```

Result: SQLite reset and seeding succeeded.

```text
user@example.com / test
admin@example.com / admin
```

Why: verifies model initialization and provides deterministic users for manual and Playwright login checks.

### Start and smoke-check Flask

```bash
APPNAME_ENV=dev FLASK_APP=manage env/bin/flask --debug run
```

In another terminal:

```bash
curl -I http://127.0.0.1:5000/
```

Result: HTTP 200.

Why: passing tests do not prove the WSGI app starts or its landing route is reachable.

## Compatibility correction found during baseline setup

`Flask-Caching` was pinned to `2.5.0`. Backend identifiers were modernized:

```text
Production: RedisCache
Development: SimpleCache
Test: NullCache
```

Files:

```text
requirements.txt
appname/settings.py
tests/test_config.py
```

Why: the old `redis`, `simple`, and `null` aliases did not match the current dependency's expected configuration. Tests were updated alongside behavior.

Verification:

```bash
APPNAME_ENV=test env/bin/python -m pytest -q tests/test_config.py
env/bin/python -m pip check
```

## Step 3 — Install the QA toolchain

### Development requirements

Created `requirements-dev.txt`:

```text
-r requirements.txt

# Assessment quality pipeline
bandit==1.9.4
playwright==1.62.0
pytest-playwright==0.9.0
ruff==0.16.5
```

Installed with:

```bash
env/bin/python -m pip install -r requirements-dev.txt
env/bin/python -m pip check
```

Why: production dependencies remain separate from lint, security, test, and browser tooling. Pins improve local/CI repeatability.

### Install Playwright Chromium

```bash
env/bin/playwright install chromium
env/bin/playwright install-deps chromium
```

The OS dependency command may need elevated package-manager privileges.

Why: the Python package alone does not contain a browser executable; Chromium and Linux libraries are required for a real headless test.

### Browser launch smoke test

Reproducible equivalent:

```bash
env/bin/python -c "from playwright.sync_api import sync_playwright; \
p=sync_playwright().start(); b=p.chromium.launch(headless=True); \
page=b.new_page(); page.set_content('<title>QA smoke</title>'); \
print(page.title()); b.close(); p.stop()"
```

Result: Chromium launched and printed `QA smoke`.

### Record versions

```bash
env/bin/python --version
env/bin/python -m pip --version
env/bin/python -m pytest --version
env/bin/ruff --version
env/bin/bandit --version
env/bin/playwright --version
```

Why: version evidence helps diagnose local/CI differences.

## Step 4 — Rebrand Ignite as MyTemplate

### Inventory legacy references

```bash
git grep -n -i -E "ignite|appname\.com|support@" -- \
  README.md app.json appname documentation tests
find appname/static/public -maxdepth 2 -type f | sort
```

Ripgrep (`rg`) was checked first but was not installed in this WSL environment,
so Git's built-in grep and `find` were used as the reproducible fallback.

Why: branding existed in configuration, templates, email copy, docs, deployment examples, and static assets.

### Centralize brand values

`appname/services/branding.py` now supplies:

```text
Name: MyTemplate
Legal name: MyTemplate
Website: mytemplate.example
Support email: support@mytemplate.example
Icon: public/mytemplate/mytemplate-icon.svg
Logo: public/mytemplate/mytemplate-logo.svg
```

`appname/settings.py` now uses:

```text
MyTemplate <admin@mytemplate.example>
```

Why: central values keep UI, email, metadata, and support identity consistent.

### Rename and replace assets

Changed the asset location from:

```text
appname/static/public/ignite/
```

to:

```text
appname/static/public/mytemplate/
```

Git-aware commands for tracked assets:

```bash
mkdir -p appname/static/public/mytemplate
git mv appname/static/public/ignite/ignite-icon.svg \
  appname/static/public/mytemplate/mytemplate-icon.svg
git mv appname/static/public/ignite/ignite-logo.svg \
  appname/static/public/mytemplate/mytemplate-logo.svg
git mv appname/static/public/ignite/stripe-purchase.png \
  appname/static/public/mytemplate/stripe-purchase.png
```

Obsolete Ignite raster logo variants were removed. SVG wordmark, dimensions, and paths were updated. A fresh Playwright screenshot replaced the old dashboard demo image.

Why: template text alone would leave stale favicons, screenshots, and logos visible.

### Update application surfaces

Changes covered:

- landing page, title, favicon, and terms;
- login, signup, invitation, reauthentication, and password reset;
- dashboard headers, footers, and minimal layouts;
- store and purchase receipt emails;
- model and mailer copy;
- `app.json`;
- README, quickstart, and Dokku examples; and
- `.gitignore` intent for the new asset path.

Authentication titles changed from `Login Example` to `Login`. Old sales copy was removed from README. Upstream attribution and the original license were retained.

Why: a genuine rebrand covers customer and operator surfaces while preserving legal provenance.

### Audit remaining Ignite references

```bash
git grep -n -i "ignite"
```

Reviewed remaining references are intentional:

- original license/copyright;
- README upstream attribution;
- attribution/source/license links in UI; and
- an external CSS CDN URL containing the upstream name.

Why: legal attribution and valid third-party URLs should not be erased.

### Visual browser verification

Flask ran locally while Playwright inspected landing and login pages. Checks confirmed MyTemplate titles/wordmarks and the new icon URL. This pass caught a stale Ignite dashboard screenshot that text search could not detect; it was replaced and rechecked.

The in-app browser automation was attempted first but could not run in the workspace sandbox, so the project's installed Playwright Chromium was used.

Why: raster images are opaque to `rg`, and template correctness does not prove real browser rendering.

### Regression verification

```bash
make agent-test
APPNAME_ENV=test env/bin/python -m pytest -q \
  tests/test_config.py tests/test_urls.py tests/test_login.py
```

Results:

```text
Full suite: 102 passed, 86% coverage
Focused config/URL/login group: 11 passed
JSON validation: passed
SVG validation: passed
Whitespace checks: passed
```

## Commit strategy

Changes were split so dependency compatibility can be reviewed independently from the rebrand.

### Commit 1 — compatibility and QA dependencies

```text
f213128 chore: update Flask compatibility and QA dependencies
```

Files:

```text
appname/settings.py       cache backend identifiers only
requirements.txt          Flask-Caching 2.5.0
requirements-dev.txt      assessment QA tools
tests/test_config.py      cache assertions
```

Selective staging workflow:

```bash
git restore --staged .
git add requirements.txt requirements-dev.txt tests/test_config.py
git add -p appname/settings.py
git diff --cached
git commit -m "chore: update Flask compatibility and QA dependencies"
```

In `git add -p`, stage cache hunks and skip the MyTemplate mail sender. Responses: `y` stage, `n` skip, `s` split.

Why: partial staging lets one modified file participate in two logical commits without losing work.

### Commit 2 — rebrand

```text
8e12619 Rebrand application as MyTemplate
```

Review workflow:

```bash
git add -A
git diff --cached --stat
git diff --cached
git commit -m "Rebrand application as MyTemplate"
git log --oneline --decorate -5
git status --short
```

Important: the post-commit audit found the new static assets were ignored and absent from this commit. See the corrective action at the top.

## Automation used so far

### Existing Makefile targets

```bash
make agent-setup    # create env and install base requirements
make agent-resetdb  # reset/seed development database
make agent-smoke    # fast URL and login tests
make agent-test     # tracked tests with coverage
```

These reduce command drift and provide a base for CI.

### Playwright

Used for:

1. headless Chromium launch verification;
2. rendered landing/login inspection; and
3. generation of the rebranded demo screenshot.

Pytest checks application behavior; Playwright checks what a user sees.

### AI-assisted workflow

Codex helped inspect the repository, interpret requirements, apply scoped edits, run validations, and inspect local UI screenshots. Material results were validated with deterministic Git, pytest, coverage, Flask, or Playwright commands. AI accelerated implementation but did not replace test evidence.

## Warnings and decisions

1. Python 3.14 is newer than the likely CI version; compare against stable CI Python.
2. Requests emits a dependency warning. It is non-blocking now but should be resolved or documented.
3. Flask-RQ2/Flask-Limiter may emit dependency warnings; distinguish them from project failures.
4. Never commit `.env`, API keys, OAuth/Stripe secrets, or local databases.
5. Preserve upstream license/attribution while removing visible legacy branding.
6. Check `git status` before/after commits. Clean status does not prove ignored assets are tracked; use `git ls-files` and `git check-ignore`.
7. Ripgrep is not installed in WSL; use `git grep`, `grep`, or `find` unless it is added deliberately.

## Step 5 — Add a meaningful backend pytest

### Confirm the exact assignment requirement

The PDF requires at least one backend test using pytest. It says the backend and UI tests should cover a real user-facing flow, remain small but meaningful, and avoid an oversized test framework.

Poppler was unavailable in WSL, so `pypdf==6.16.2` was installed only in the existing virtual environment to extract the three-page assignment. It was deliberately not added to project requirements because the application and CI pipeline do not depend on it.

```bash
env/bin/python -m pip install pypdf
```

Why: returning to the source requirement prevented overbuilding and confirmed that one focused backend test is sufficient.

### Select the behavior

The existing `tests/test_urls.py` already checked that `GET /` returns HTTP 200, but did not verify the assignment's rebrand. The new test renders the public landing page through the Flask test client and checks:

- HTTP 200;
- the `MyTemplate` page title;
- the visible MyTemplate logo alternative text;
- the MyTemplate SVG icon URL; and
- the MyTemplate demo screenshot URL.

File: `tests/test_branding.py`
Test: `test_landing_page_displays_mytemplate_branding`

The module sets `create_user = False` because this anonymous landing-page flow does not need database users. It reuses the existing `testapp` fixture and introduces no new framework.

Why: this is a real public user-facing response, directly verifies the required application change, and adds value beyond the existing status-only test.

### Focused baseline and new-test commands

```bash
APPNAME_ENV=test env/bin/python -m pytest -q \
  tests/test_urls.py::TestURLs::test_home

APPNAME_ENV=test env/bin/python -m pytest -q tests/test_branding.py
```

Results:

```text
Existing homepage baseline: 1 passed
New backend test: 1 passed
```

### Full regression command

The current `make agent-test` target expands only `git ls-files 'tests/*.py'`. Because the new test is not committed yet, that target would omit it. Full discovery was therefore run explicitly:

```bash
APPNAME_ENV=test env/bin/python -m pytest \
  --cov-report=term-missing \
  --cov=appname \
  tests/
```

Result: **103 passed**, **113 warnings**, **86% total coverage**, in **28.65 seconds**. The extra test increased the count from 102 to 103; rounded total coverage remained unchanged.

### Focused quality and dependency checks

```bash
env/bin/ruff check tests/test_branding.py
env/bin/python -m pip check
git diff --check
```

Results:

```text
Ruff: All checks passed
pip check: No broken requirements found
Git whitespace check: passed
```

Warnings remain dependency/runtime warnings already recorded elsewhere: Requests compatibility, deprecated `pkg_resources` use, Flask-Limiter's in-memory test storage, SQLAlchemy-Utils encryption migration, and a debug-toolbar response warning. No warning caused a failure.

## Step 6 — Add a meaningful pytest-playwright UI test

### Select the user journey

The UI test covers an anonymous visitor opening the public landing page, confirming the MyTemplate title, clicking the real `Demo` link, reaching `/signup`, and seeing the MyTemplate signup form. It also verifies that the MyTemplate logo actually decoded in Chromium by checking `image.complete` and `naturalWidth > 0`.

File: `tests/test_ui_signup.py`
Test: `test_visitor_can_open_mytemplate_signup`

Why: this is a small, real customer flow tied directly to the rebrand. It tests browser navigation, accessibility roles, rendered content, and a loaded asset without building a large UI framework.

### Make the test self-contained

A function-scoped `live_server_url` fixture:

1. creates the Flask app with the existing test configuration;
2. disables only the Flask debug toolbar for customer-UI testing;
3. binds a Werkzeug server to `127.0.0.1` on port `0`, allowing the OS to choose an available port;
4. runs the server in a daemon thread;
5. yields the generated base URL; and
6. shuts down, closes, and joins the server thread during teardown.

Why: the test needs no manually started Flask process, fixed port, external database, or seeded account. An ephemeral port also reduces collisions locally and in CI.

The test uses Playwright's role and text locators:

```text
link named Demo
text Sign up for MyTemplate
button named Sign Up
image named MyTemplate logo
```

These match the accessible UI rather than fragile CSS layout details.

### Browser tooling decision

The in-app browser runtime was attempted as required by the browser-testing workflow, but its Windows sandbox helper exited before a browser could be selected. Because no specific interactive browser was requested, testing continued with the repository's installed Playwright Chromium. This is also the exact framework required by the assignment and is suitable for CI.

Chromium availability was confirmed with:

```bash
env/bin/playwright install --dry-run chromium
```

### First test run and diagnosed failure

```bash
env/bin/ruff check tests/test_ui_signup.py
APPNAME_ENV=test env/bin/python -m pytest -q tests/test_ui_signup.py \
  --browser chromium \
  --tracing retain-on-failure \
  --screenshot only-on-failure \
  --output tmp/playwright
```

Ruff passed. The first Chromium run failed after 37.07 seconds because Flask's development debug toolbar overlaid the page and intercepted the click on `Demo`. Playwright's call log identified the intercepting `flDebug` elements.

Failure artifacts were generated successfully:

```text
test-failed-1.png  235,135 bytes
trace.zip           102,121,727 bytes
```

Why this was fixed in configuration: using `force=True` on the click would bypass real actionability and weaken the test. A UI test should render the customer surface, not development instrumentation.

The test now uses a small `UITestConfig(TestConfig)` subclass with:

```python
DEBUG_TB_ENABLED = False
```

This affects only the UI test app. The verified temporary failure-artifact directory was deleted before the clean rerun so stale failures could not be mistaken for current output.

### Corrected focused result

The same command was rerun after the test-only configuration correction.

```text
Ruff: All checks passed
UI test: 1 passed, 5 warnings, 1.91 seconds
```

The successful run confirmed:

- the landing response was successful;
- the page title was `MyTemplate`;
- the real `Demo` link was clickable;
- navigation reached the dynamically allocated server's `/signup` URL;
- the title became `MyTemplate Signup`;
- the signup heading and button were visible; and
- the logo loaded and decoded successfully.

With `retain-on-failure` and `only-on-failure`, a passing run correctly left no files under `tmp/playwright`.

### Complete backend and UI regression run

```bash
APPNAME_ENV=test env/bin/python -m pytest \
  --cov-report=term-missing \
  --cov=appname \
  tests/ \
  --browser chromium \
  --tracing retain-on-failure \
  --screenshot only-on-failure \
  --output tmp/playwright
```

Result: **104 passed**, **114 warnings**, **86% total coverage**, in **29.85 seconds**. This verifies that the live-server fixture and browser test do not interfere with the backend suite.

## Step 7 — Configure Ruff, Bandit, coverage, and reports

### Establish unsuppressed baselines

Ruff and Bandit were first run without adding suppressions:

```bash
env/bin/ruff check . --output-format=json
env/bin/bandit -r appname -f json
```

Bandit found one high-severity, high-confidence `B324` finding in `appname/services/security.py`: MD5 was used to derive the serializer's short unique salt.

Ruff's broad effective profile reported 182 findings:

```text
51 I001 import ordering
28 UP032 f-string modernization
25 RUF012 mutable class defaults
20 F401 unused imports
58 other modernization, style, and correctness findings
```

Why: the baseline was captured before configuration so tool scope decisions were transparent rather than chosen only to manufacture a passing result.

### Fix the security finding

The token serializer salt derivation changed from:

```python
hashlib.md5(encoded_secret).hexdigest()[:5]
```

to:

```python
hashlib.sha256(encoded_secret).hexdigest()[:5]
```

No Bandit suppression was added. This change invalidates previously issued short-lived tokens, which is acceptable during this starter-project assessment and preferable to retaining a weak hash in security-related code.

Final command:

```bash
env/bin/bandit -r appname -f json -o reports/bandit.json
```

Result:

```text
Exit code: 0
Findings: 0
High: 0
Medium: 0
Low: 0
```

### Define a practical Ruff policy

A local `pyproject.toml` now makes lint behavior independent of machine-level defaults:

```toml
[tool.ruff]
line-length = 120
target-version = "py312"
extend-exclude = ["env", "migrations"]

[tool.ruff.lint]
select = ["E4", "E7", "E9", "F"]
```

Python 3.12 matches `runtime.txt`. The selected rules enforce import/syntax/runtime correctness without turning the time-boxed assessment into an unrelated modernization of the legacy starter project.

Under this explicit scope, Ruff found 23 actionable issues. Ruff applied 19 marked-safe fixes; four were handled deliberately:

- removed two unused Flask-RESTful imports from `appname/api/__init__.py`;
- declared the OAuth blueprint in `__all__` because it is an intentional package re-export; and
- renamed the ambiguous `l` argument in `chunks` to `values`.

The invalid legacy `# noqa;` syntax on the transaction rollback handler was also corrected to a narrow `# noqa: E722` with a reason. Other safe fixes removed unused imports, a duplicate Stripe import, and an extra `.format()` argument.

Commands:

```bash
env/bin/ruff check . --select E4,E7,E9,F --output-format=concise
env/bin/ruff check . --fix --show-fixes
env/bin/ruff check . --output-format=json --output-file reports/ruff.json
```

Result:

```text
Exit code: 0
Remaining findings: 0
Safe automatic fixes: 19
```

### Standardize artifact locations

Coverage configuration now writes default HTML and XML output under `reports/`. The redundant `include = appname/*` setting was removed because `--cov=appname` already sets the source and caused an avoidable Coverage warning.

A tracked `reports/README.md` explains the output. Generated files are ignored by Git because local builds and CI recreate them:

```text
reports/pytest.xml
reports/playwright.xml
reports/coverage.xml
reports/coverage-html/index.html
reports/ruff.json
reports/bandit.json
reports/playwright/
```

Playwright traces and screenshots use retain-on-failure behavior, so the directory is empty/absent after a successful UI run and populated only when diagnosis is needed.

### Generate the complete test and coverage artifacts

```bash
APPNAME_ENV=test env/bin/python -m pytest tests/ \
  --browser chromium \
  --tracing retain-on-failure \
  --screenshot only-on-failure \
  --output reports/playwright \
  --junitxml=reports/pytest.xml \
  --cov=appname \
  --cov-report=term-missing \
  --cov-report=xml:reports/coverage.xml \
  --cov-report=html:reports/coverage-html
```

Final result:

```text
Tests: 104
Failures: 0
Errors: 0
Skipped: 0
Terminal coverage: 86%
Coverage XML line rate: 87.46%
Coverage XML branch rate: 74.78%
Warnings: 113
Duration: 30.94 seconds
Playwright failure artifacts: 0
```

The remaining warnings come from existing dependencies and test-mode behavior: deprecated `pkg_resources` use, SQLAlchemy-Utils encryption migration, Flask-Limiter in-memory storage, Requests dependency compatibility, and debug-toolbar behavior on body-less webhook responses. The redundant coverage warning is resolved.

### Validate reports

PowerShell's native JSON and XML parsers were used to reopen the outputs. Validation confirmed:

- `ruff.json` is valid JSON containing an empty finding list;
- `bandit.json` is valid JSON with zero findings and zero severity totals;
- `pytest.xml` and `playwright.xml` contain 103 backend plus 1 UI test case, with no failures or errors;
- `coverage.xml` is valid XML with line and branch rates;
- `coverage-html/index.html` exists; and
- no Playwright failure files remain after the passing run.

Why: a command claiming that it wrote a report is not proof that the file is parseable or contains the expected result.

## Step 8 — Add the repeatable Makefile pipeline

### Define one local and CI command contract

The Makefile now exposes these user-facing targets:

```text
make setup              environment + dev dependencies + Chromium
make deps               application and QA dependencies
make browser-install    local Chromium installation
make browser-install-ci Chromium plus Linux dependencies for CI
make lint               Ruff JSON report
make security           Bandit JSON report
make test-backend       backend JUnit and coverage reports
make test-ui            Chromium UI JUnit and failure artifacts
make reports            all quality and test targets
make check              alias for the complete reports pipeline
make ci                 CI entry point; alias for make check
make clean-reports      remove generated reports, preserving the README
```

The legacy `make test`, `make agent-test`, `make agent-smoke`, `make agent-resetdb`, and `make agent-setup` entry points remain available. `test` and `agent-test` now delegate to the backend report-producing target.

Why: local developers and CI should invoke the same commands. Separate targets keep failures easy to isolate, while `make ci` provides one panel-friendly entry point.

### Make setup repeatable

The Makefile defines overridable `PYTHON` and `VENV` variables, with tool paths derived from the virtual environment. Setup uses:

```make
deps: env
    env/bin/python -m pip install --upgrade pip
    env/bin/python -m pip install -r requirements-dev.txt

browser-install:
    env/bin/playwright install chromium

browser-install-ci:
    env/bin/playwright install --with-deps chromium
```

The CI-specific browser target installs Linux libraries as well as Chromium. The local target avoids invoking the system package manager unnecessarily.

### Generate reports through dedicated targets

`make lint` writes `reports/ruff.json`, and `make security` writes `reports/bandit.json`.

The backend and UI layers are intentionally separate:

```text
test-backend: 103 tests
  reports/pytest.xml
  reports/coverage.xml
  reports/coverage-html/index.html

test-ui: 1 Chromium test
  reports/playwright.xml
  reports/playwright/ only when a failure occurs
```

Why: the assignment requests a unit test report and UI test output. Separate JUnit files make each layer directly reviewable while the aggregate remains 104 tests.

### Preserve safe cleanup behavior

`make clean-reports` contains a guard requiring `REPORT_DIR` to equal `reports`, deletes only descendants of that directory, and preserves `reports/README.md`.

The general `clean` target is restricted to Python bytecode/cache files under `appname/` and `tests/`; it no longer targets databases or traverses the virtual environment.

Why: cleanup automation should be predictable and recoverable from source, without risking application data.

### Validate command expansion before execution

```bash
make help
make -n setup
make -n clean-reports
make -n ci
```

The dry runs confirmed:

- dependency installation appears once in the setup graph;
- local setup installs Chromium without system packages;
- report cleanup remains scoped to `reports/`;
- CI expands in the order Ruff, Bandit, backend tests, then UI tests; and
- all tools write to the documented report paths.

### Execute the complete pipeline

```bash
make ci
```

Expanded commands:

```text
env/bin/ruff check . --output-format=json --output-file reports/ruff.json
env/bin/bandit -r appname -f json -o reports/bandit.json
APPNAME_ENV=test env/bin/python -m pytest tests/ --ignore=tests/test_ui_signup.py ...
APPNAME_ENV=test env/bin/python -m pytest tests/test_ui_signup.py --browser chromium ...
```

Final result:

```text
Make exit code: 0
Ruff findings: 0
Bandit findings: 0
Backend tests: 103 passed, 0 failures, 0 errors, 28.22 seconds
UI tests: 1 passed, 0 failures, 0 errors, 3.14 seconds
Aggregate tests: 104 passed
Backend terminal coverage: 86%
```

Both JUnit files were reopened with an XML parser after the run. The backend report contains 103 cases and the UI report contains 1 case, with no failures or errors.

Warnings remain the already documented dependency and test-mode warnings; none caused a Make target to fail. Because Make propagates non-zero command statuses, a Ruff, Bandit, backend, or UI failure stops `make ci` with a failing exit code.

## Step 9 — Upgrade GitHub Actions CI

### Reuse and modernize the existing workflow

Updated `.github/workflows/flask-pytest.yml` rather than adding a second workflow. The legacy workflow ran only pytest, installed only `requirements.txt`, used a separate cache action, wrote one JUnit file outside the standard report directory, and did not install or execute the requested QA tools and browser test.

Why: one authoritative workflow avoids duplicate jobs and keeps the CI implementation aligned with the repository's single local command contract.

### Configure when and how CI runs

The workflow is named `MyTemplate Quality CI` and runs on:

- every push;
- every pull request; and
- manual `workflow_dispatch`.

It grants only `contents: read`, applies a 20-minute job timeout, and uses a concurrency group based on workflow and Git reference with `cancel-in-progress: true`.

Why: push and pull-request checks protect normal development, manual dispatch helps demonstrations, least-privilege permissions reduce exposure, and concurrency avoids wasting runner time on superseded commits.

### Use current official actions and a stable Python line

The action versions were checked against their official repositories on 1 September 2026:

- `actions/checkout@v7`;
- `actions/setup-python@v7`; and
- `actions/upload-artifact@v7`.

References:

- <https://github.com/actions/checkout>
- <https://github.com/actions/setup-python>
- <https://github.com/actions/upload-artifact>

The job uses `ubuntu-latest` with Python `3.14`. The local verification environment is Python 3.14.4, so local and hosted runs use the same stable interpreter family. The minor-version selector allows the hosted runner to use the current supported 3.14 patch.

`setup-python` provides pip caching directly. Its cache key includes both `requirements.txt` and `requirements-dev.txt`, so application or QA dependency changes invalidate the cache. This replaces the older standalone `actions/cache` step, whose key included only `requirements.txt`.

A single Python job is intentional. The assignment asks for a stable repeatable pipeline, not a compatibility matrix, and duplicating Chromium installation and the browser suite across versions would add time without improving the requested evidence.

### Delegate installation and checks to Make

The workflow executes:

```bash
make browser-install-ci
make ci
```

`make browser-install-ci` depends on `deps`, so it creates `env/`, installs the pinned development requirements, then runs:

```bash
env/bin/playwright install --with-deps chromium
```

The hosted job therefore installs both Chromium and its Ubuntu system libraries. Calling `make deps` separately would duplicate dependency installation, so the workflow relies on the Make dependency graph.

`make ci` then runs the same sequence verified locally:

1. Ruff with JSON output;
2. Bandit with JSON output;
3. backend pytest with JUnit and XML/HTML coverage; and
4. pytest-playwright in Chromium with JUnit plus failure traces/screenshots.

### Retain reviewable evidence

The final step uses `if: always()` to upload `reports/` as the `quality-reports` artifact for 14 days. `if-no-files-found: warn` avoids hiding the original quality failure if a very early command prevents report generation.

Because `reports/README.md` is tracked, the artifact also explains each generated file. Any reports completed before a failing Make target remain downloadable for diagnosis.

### Validate the workflow and simulate CI locally

Inspection and dry-run commands:

```bash
git diff -- .github/workflows/flask-pytest.yml reports/README.md
git diff --check
make -n browser-install-ci
make -n ci
```

The dry run confirmed dependency installation, Chromium plus Linux dependency installation, and the complete quality target sequence.

PyYAML's base loader was used for a structural assertion without the YAML 1.1 special treatment of the key `on`:

```bash
env/bin/python -c 'import yaml; p=yaml.load(open(".github/workflows/flask-pytest.yml", encoding="utf-8"), Loader=yaml.BaseLoader); assert set(p["on"]) == {"push", "pull_request", "workflow_dispatch"}; q=p["jobs"]["quality"]; assert q["runs-on"]=="ubuntu-latest"; s=q["steps"]; assert [x.get("uses") for x in s if "uses" in x] == ["actions/checkout@v7", "actions/setup-python@v7", "actions/upload-artifact@v7"]; assert [x.get("run") for x in s if "run" in x] == ["make browser-install-ci", "make ci"]; assert s[-1]["if"]=="always()"; print("workflow YAML structure: valid")'
```

Result: `workflow YAML structure: valid`.

The first attempt to send the nested Python command through a PowerShell-wrapped `wsl.exe bash -lc` invocation failed at PowerShell parsing before any project command ran. The command was rerun inside an interactive WSL Bash shell, which preserved the quotes and passed. A later report-extraction one-liner encountered the same wrapper issue and used the same safe workaround. No repository files were changed by either failed wrapper command.

Local simulation:

```bash
make ci
```

Final result on Python 3.14.4:

```text
Make exit code: 0
Ruff findings: 0
Bandit findings: 0
Backend tests: 103 passed, 0 failures, 0 errors, 30.69 seconds
UI tests: 1 passed, 0 failures, 0 errors, 2.58 seconds
Aggregate tests: 104 passed
Terminal coverage: 86%
Coverage XML line rate: 87.46%
Coverage XML branch rate: 74.78%
```

The warnings are the existing dependency and test-mode warnings already documented in Step 7. They do not fail the pipeline.

Remote status: the workflow has not been pushed or run on GitHub yet. This is deliberate because the assignment says a local command simulation is sufficient and the user has not requested a push. Once pushed, the GitHub Actions run URL and artifact result can be appended here.

## Step 10 — Final repository and submission review

### Inspect branch history and the complete change set

Commands:

```bash
git branch --show-current
git remote -v
git log --oneline --decorate --graph cec9b16..HEAD
git status --short --untracked-files=all
git diff --check cec9b16..HEAD
git diff --check
git diff --check cec9b16
git diff --name-status cec9b16..HEAD
git diff --stat cec9b16..HEAD
git diff --shortstat cec9b16
```

Result:

- branch: `assessment/mytemplate`;
- origin: `https://github.com/yashwanthvasili/mytemplate-devops-assessment.git`;
- upstream: `https://github.com/Sumukh/Ignite.git`;
- committed assessment changes: `f213128` and `8e12619`;
- combined tracked comparison at audit time: 53 files changed, 283 insertions, and 291 deletions; and
- combined tracked diff whitespace validation: passed.

The origin URL did not appear in a public web search, which is consistent with a private or not-yet-indexed repository. GitHub CLI was not installed and no authenticated repository API was available, so private visibility and reviewer access must be confirmed in GitHub before submission.

### Verify replacement assets and branding boundaries

Commands:

```bash
git ls-files appname/static/public/mytemplate
git status --short --untracked-files=all
git check-ignore -v appname/static/public/mytemplate/demo-1.png
find appname/static/public/mytemplate -maxdepth 1 -type f -printf '%f %s bytes\\n' | sort
file appname/static/public/mytemplate/*
git grep -n -i ignite -- . ':!LICENSE.md'
git grep -n -E 'static/public/ignite|public/ignite|ignite/' -- .
```

The four replacement assets are valid PNG/SVG files:

```text
demo-1.png             82,549 bytes, PNG 1280 x 800 RGB
mytemplate-icon.svg     1,609 bytes, valid SVG XML
mytemplate-logo.svg     1,895 bytes, valid SVG XML
stripe-purchase.png    82,919 bytes, PNG 1360 x 763 RGBA
```

The Chromium test also loaded the MyTemplate logo with a nonzero natural width. No active reference to the removed `static/public/ignite` path remains outside the historical commands in this execution log.

Remaining tracked uses of “Ignite” are intentional attribution/source references in the README, footer/landing pages, and the upstream CSS URL. They do not present the application itself as Ignite.

Important commit warning: `git ls-files appname/static/public/mytemplate` is empty because the four replacement files are still untracked. They are no longer ignored and are ready to add, but they must be explicitly staged before the next commit. Otherwise the submitted repository would delete the old Ignite assets without adding their replacements.

### Scan for secrets, generated outputs, and large files

Credential-pattern scan covered tracked and untracked files for common AWS, GitHub, Stripe, webhook, and private-key formats. No matches were found.

Environment handling:

```text
.env.local.sample: tracked example only
.env.local: ignored by *.env*
```

Generated QA outputs are correctly ignored by `reports/*`, while `reports/README.md` is re-included and ready to commit. The parsed generated outputs are:

```text
reports/ruff.json
reports/bandit.json
reports/pytest.xml
reports/playwright.xml
reports/coverage.xml
reports/coverage-html/index.html
```

An existing `env-py314-backup/` directory is ignored by `env*` and occupies approximately 235 MiB. It contains virtual-environment dependencies and cannot enter a normal `git add`. It was left untouched because it may be a user-created backup.

The only file larger than 1 MiB outside Git metadata, active/backup environments, and generated reports is the pre-existing tracked Tabler Material Design icon-font SVG (approximately 2.2 MiB). No new assessment asset exceeds 83 KiB.

The preferred `rg` search executable was unavailable in the WSL shell during this audit, so the skipped searches were repeated with `git grep`, recursive `grep`, `find`, and `git check-ignore`.

### Correct reviewer-facing documentation

Final review found that README, `AGENTS.md`, and `documentation/AGENT_QUICKSTART.md` still described `make agent-test` as the full suite even though the new Playwright test is intentionally separate.

Corrections:

- README setup now uses `make setup`;
- README testing now uses `make ci` and documents `reports/` plus the `quality-reports` artifact;
- the malformed seeded-login example quote was corrected;
- `AGENTS.md` recommends `make ci` for final handoff and labels `make agent-test` as backend-only; and
- the quickstart uses the same setup/full-pipeline commands and points to generated evidence.

Why: the primary reviewer path must exercise exactly the same automation as CI. A technically correct Makefile is not enough if the top-level instructions send reviewers through an older, incomplete command.

### Execute the final quality gate

Command:

```bash
make ci
```

Final result on Python 3.14.4:

```text
Make exit code: 0
Ruff findings: 0
Bandit findings: 0
Backend tests: 103 passed, 0 failures, 0 errors, 29.64 seconds
UI tests: 1 passed, 0 failures, 0 errors, 2.89 seconds
Aggregate tests: 104 passed
Terminal coverage: 86%
Coverage XML line rate: 87.46%
Coverage XML branch rate: 74.78%
```

A final parser reopened the workflow YAML, Ruff/Bandit JSON, both JUnit XML files, coverage XML, coverage HTML index, and both SVG files. It also checked Markdown fence balance in README, `AGENTS.md`, the agent quickstart, and this execution log. All assertions passed.

The known third-party/test-mode warnings remain unchanged and non-failing.

### Final local state

The assignment implementation is complete and locally verified. No files were staged, no new commit was created, and nothing was pushed during Step 10.

Before submission:

1. explicitly stage all required untracked files, especially the four MyTemplate assets;
2. review the staged diff;
3. create focused commit(s);
4. push `assessment/mytemplate` to `origin`;
5. confirm the repository is private and the reviewer has access; and
6. optionally record the GitHub Actions run URL and downloaded `quality-reports` artifact in this log.

### Post-audit commit preparation

The implementation/QA files were staged explicitly rather than with a broad `git add .`. This included all four replacement assets plus the Makefile, workflow, test/configuration files, scanner fixes, and reports manifest.

Validation:

```bash
git diff --cached --check
git diff --cached --name-status
git diff --cached --stat
```

The staged diff contained 25 files, 273 insertions, and 89 deletions. The four MyTemplate assets appeared as added files, while README, `AGENTS.md`, the quickstart, and this execution log remained unstaged.

Commit:

```bash
git commit -m 'ci: add automated QA and browser test pipeline'
```

Result:

```text
86f6cca ci: add automated QA and browser test pipeline
```

The reviewer documentation is kept in a second focused commit using:

```bash
git add -- AGENTS.md README.md documentation/AGENT_QUICKSTART.md documentation/ASSESSMENT_EXECUTION_LOG.md
git diff --cached --check
git commit -m 'docs: document assessment workflow and verification'
```

### Push attempt and authentication diagnosis

The final history was revalidated before pushing:

```bash
git status --short --branch
git log --oneline --decorate --graph cec9b16..HEAD
git diff --check cec9b16..HEAD
git ls-files appname/static/public/mytemplate
git ls-remote --heads origin assessment/mytemplate
```

The worktree was clean, all four assets were tracked, and the remote branch was not present.

The authorized push command was then attempted:

```bash
git push --set-upstream origin assessment/mytemplate
```

It produced no output or prompt for more than one minute, so it was interrupted without using force. A non-interactive credential check returned:

```text
fatal: could not read Username for 'https://github.com': terminal prompts disabled
```

Diagnostics found no `GH_TOKEN`, `GITHUB_TOKEN`, GitHub CLI, WSL credential helper, Windows Git Credential Manager, or SSH key. An unauthenticated GitHub repository API request returned HTTP 404, which is consistent with a private or nonexistent repository but cannot prove private visibility without authentication.

Resolution: authenticate GitHub securely in an interactive terminal, then rerun the same non-force push. Do not paste a personal access token into this execution log or chat.

## Per-change template

Copy for each future unit:

```markdown
### YYYY-MM-DD — Short title

Requirement:

Files changed:

Why:

Commands:

    # exact commands

Automation/tooling used:

Result:

Warnings/failures:

Resolution:

Evidence/report path:

Commit:

Next action:
```

## Concise interview explanation

The work began with a verified baseline: dependencies installed, configuration tests passing, database seeding successful, Flask returning HTTP 200, and all 102 existing tests passing at 86% coverage. A focused backend branding test and a real Chromium landing-to-signup flow then raised the combined suite to 104 passing tests while coverage remained 86%. QA tools were isolated in pinned development requirements, and Playwright Chromium was smoke-tested. The rebrand covered centralized branding, templates, email, metadata, documentation, and assets, followed by automated and browser checks. The browser pass caught a stale raster screenshot that text search could not find. Selective Git staging separated compatibility/tooling from the rebrand. A post-commit audit then caught that replacement assets were still ignored; that is documented as the first follow-up fix. Remaining work is GitHub Actions with artifact upload configuration and final end-to-end verification.
