# MyTemplate DevOps and QA Assessment — Execution Log

## Document control

| Field | Value |
| --- | --- |
| Role | DevOps Support and QA Engineer |
| Repository | `mytemplate-devops-assessment` |
| Assessment branch | `assessment/mytemplate` |
| Upstream baseline | `upstream/master` at `cec9b16` |
| Implementation checkpoint | `0cd897d`; final documentation is the branch tip |
| Log refreshed | 2 September 2026 |
| Primary local quality gate | `make ci` |

This log is the concise engineering record for the assessment. Assignment
requirements are treated as requirements; the implementation notes below record
our decisions, commands, evidence, and rationale.

Supporting references:

- `README.md` provides the short local setup and quality-check instructions.
- `reports/README.md` describes generated QA artifacts.

## Executive summary

The assessment was completed with a deliberately small implementation:

1. Established a working baseline and corrected Flask-Caching compatibility.
2. Renamed the application from Ignite to MyTemplate across code, UI, assets,
   metadata, email, and reviewer documentation.
3. Added one meaningful backend branding test.
4. Added one meaningful Playwright browser journey from the landing page to
   signup.
5. Added Ruff, Bandit, branch coverage, JUnit, XML, HTML, and browser evidence.
6. Standardized local and CI execution through `make ci`.
7. Updated GitHub Actions to run the same Make targets and retain reports.
8. Audited tracked files for secrets, generated output, stale branding, and
   unrelated changes.

No unrelated product feature or oversized test framework was introduced. AWS
deployment was not implemented because it is an optional bonus.

## Requirement traceability

| Assignment requirement | Implementation | Evidence | Status |
| --- | --- | --- | --- |
| Rename Ignite to MyTemplate | Central brand service, templates, metadata, mail content, documentation, and assets updated | Backend and browser branding assertions | Complete |
| Repeatable local build | `make setup` and `make ci` | `Makefile` | Complete |
| CI build process | GitHub Actions delegates to Make | `.github/workflows/flask-pytest.yml` | Complete |
| Backend Pytest | Landing-page branding behavior | `tests/test_branding.py` | Complete |
| UI Playwright test | Landing page → Demo → signup journey | `tests/test_ui_signup.py` | Complete |
| Ruff | Focused correctness/import rule set | `pyproject.toml`, `reports/ruff.json` | Complete |
| Bandit | Recursive application scan | `reports/bandit.json` | Complete |
| Coverage | Terminal, XML, HTML, and branch coverage | `.coveragerc`, `reports/coverage*` | Complete |
| Reviewable test output | Separate backend and UI JUnit reports | `reports/pytest.xml`, `reports/playwright.xml` | Complete |
| Short run notes | README plus this execution log | `README.md`, this file | Complete |
| Push to private repository | Branch tracks private origin | `origin/assessment/mytemplate` | Complete |
| AWS deployment | Optional bonus only | Not implemented | Not required |

## Execution record

### 1. Baseline and compatibility

**Action**

- Inspected repository guidance, branch state, application layout, and existing
  tests.
- Created an isolated Python environment.
- Ran focused configuration tests and the tracked backend suite.
- Corrected cache backend identifiers for current Flask-Caching.
- Pinned the verified Flask-Caching version.

**Why**

A reliable baseline separates pre-existing compatibility problems from defects
introduced by the assessment. The application could not be considered
repeatable while local and CI dependency resolution could select incompatible
cache behavior.

**Key commands**

```bash
# Inspect the starting point.
git status --short --branch
git remote -v
git log --oneline --decorate -8

# Create the isolated environment and install dependencies.
python3 -m venv env
env/bin/python -m pip install --upgrade pip
env/bin/python -m pip install -r requirements.txt

# Establish focused and full baselines.
APPNAME_ENV=test env/bin/python -m pytest -q tests/test_config.py
APPNAME_ENV=test env/bin/python -m pytest tests/ --cov=appname
```

**Changes**

- `requirements.txt`: pinned `Flask-Caching==2.5.0`.
- `appname/settings.py`: changed cache aliases to `RedisCache`,
  `SimpleCache`, and `NullCache`.
- `tests/test_config.py`: aligned assertions with canonical backend names.

**Outcome**

The application factory and existing tests initialized successfully with the
verified dependency set.

### 2. QA toolchain

**Action**

Created `requirements-dev.txt` containing the application requirements and
pinned assessment tools:

- Bandit 1.9.4
- Playwright 1.62.0
- pytest-playwright 0.9.0
- Ruff 0.16.5

Pytest, pytest-cov, and the application packages continue to come from
`requirements.txt`.

**Why**

Pinning tools makes local and CI results reproducible without adding QA-only
packages to the production dependency entry point.

**Key commands**

```bash
env/bin/python -m pip install -r requirements-dev.txt
env/bin/playwright install chromium

# CI additionally installs browser operating-system dependencies.
env/bin/playwright install --with-deps chromium
```

### 3. Ignite-to-MyTemplate rebrand

**Action**

Updated the central branding service, application metadata, configuration,
templates, email content, deployment documentation, and static assets. Removed
obsolete Ignite asset variants and added MyTemplate SVG/PNG replacements.

**Why**

The assignment required a consistent code and UI rename. Updating only the
landing page would leave mixed branding in authentication, email, store,
dashboard, deployment, and static-resource paths.

**Primary areas changed**

- `appname/services/branding.py`
- `app.json`
- `appname/settings.py`
- `appname/templates/`
- `appname/mailers/store.py`
- `appname/models/user.py`
- `appname/static/public/mytemplate/`
- `README.md` and deployment/agent documentation

**Audit commands**

```bash
# Review remaining legacy text.
git grep -n -i ignite -- ':!documentation/ASSESSMENT_EXECUTION_LOG.md'

# Ensure old static paths are gone.
git grep -n 'static/public/ignite' -- ':!documentation/ASSESSMENT_EXECUTION_LOG.md'

# Confirm replacement assets exist.
test -s appname/static/public/mytemplate/demo-1.png
test -s appname/static/public/mytemplate/mytemplate-icon.svg
test -s appname/static/public/mytemplate/mytemplate-logo.svg
test -s appname/static/public/mytemplate/stripe-purchase.png
```

**Decision**

Ignite references used for license attribution or upstream source URLs were
retained intentionally.

### 4. Backend QA test

**Action**

Added `tests/test_branding.py`.

The test requests the public landing page and verifies:

- HTTP 200.
- MyTemplate page title.
- MyTemplate image alt text.
- MyTemplate icon and demo-image paths.

**Why**

This validates visible rebranding behavior through Flask's request stack rather
than testing only an internal constant.

**Focused command**

```bash
APPNAME_ENV=test env/bin/python -m pytest -q tests/test_branding.py
```

### 5. Browser QA test

**Action**

Added `tests/test_ui_signup.py` with a self-contained Werkzeug live server and
Playwright Chromium test.

The user journey:

1. Open the landing page.
2. Confirm the MyTemplate title.
3. Click the visible `Demo` link.
4. Confirm navigation to `/signup`.
5. Verify the signup heading and button.
6. Verify the MyTemplate logo is visible and fully loaded.

**Why**

This is a small, real user-facing journey covering routing, rendering,
navigation, accessibility roles, and static-asset delivery. Keeping the live
server fixture in the test avoids a larger page-object or browser framework.

**Focused command**

```bash
APPNAME_ENV=test env/bin/python -m pytest tests/test_ui_signup.py \
  --browser chromium \
  --tracing retain-on-failure \
  --screenshot only-on-failure \
  --output reports/playwright \
  --junitxml=reports/playwright.xml
```

### 6. Static analysis, security, and coverage

**Ruff**

Added `pyproject.toml` with the focused rules `E4`, `E7`, `E9`, and `F`.
The configuration catches import, syntax, undefined-name, and significant style
problems without forcing an unrelated full-codebase restyle.

Ruff findings led to small cleanup changes such as unused-import removal,
clarifying an ambiguous argument name, and correcting a redundant format
argument.

**Bandit**

Bandit initially identified MD5 use in serializer salt derivation.
`appname/services/security.py` now uses SHA-256.

The value was not a password hash, but removing weak-hash usage produces a
cleaner security posture and a zero-finding report without suppressing the
warning.

**Coverage**

Updated `.coveragerc` to retain branch measurement and place reports under
`reports/`.

**Commands**

```bash
# Machine-readable static-analysis result.
env/bin/ruff check . --output-format=json --output-file reports/ruff.json

# Machine-readable security result.
env/bin/bandit -r appname -f json -o reports/bandit.json

# Backend JUnit plus terminal, XML, and HTML coverage.
APPNAME_ENV=test env/bin/python -m pytest tests/ \
  --ignore=tests/test_ui_signup.py \
  --junitxml=reports/pytest.xml \
  --cov=appname \
  --cov-report=term-missing \
  --cov-report=xml:reports/coverage.xml \
  --cov-report=html:reports/coverage-html
```

### 7. Make automation

**Action**

Reworked the `Makefile` so local development and CI use the same command
contract.

| Target | Purpose |
| --- | --- |
| `make setup` | Create `env/`, install dependencies, install Chromium |
| `make lint` | Run Ruff and write JSON |
| `make security` | Run Bandit and write JSON |
| `make test-backend` | Run backend tests, JUnit, and coverage |
| `make test-ui` | Run the Playwright test and failure evidence |
| `make ci` | Run the complete quality gate |
| `make clean-reports` | Remove generated reports but retain the manifest |

**Why**

A single source of truth prevents command drift. Individual targets remain
available for diagnosis, while `make ci` is the reviewer and CI entry point.

**Standard local execution**

```bash
# One-time setup.
make setup

# Repeatable full validation.
make ci
```

### 8. GitHub Actions

**Action**

Updated `.github/workflows/flask-pytest.yml` to:

- Run on push, pull request, and manual dispatch.
- Use read-only repository permission.
- Configure Python 3.14 with pip caching.
- Install Chromium and Linux dependencies with
  `make browser-install-ci`.
- Run the quality gate with `make ci`.
- Cancel stale runs for the same ref.
- Apply a 20-minute job timeout.
- Upload `reports/` as `quality-reports` even after failure.
- Retain artifacts for 14 days.

**Why**

CI should execute the same process proven locally and retain enough evidence to
diagnose failures. The assignment permits local post-commit simulation, so an
actual hosted workflow result is useful evidence but not a required condition.

### 9. Reports and repository hygiene

**Generated outputs**

| Artifact | Purpose |
| --- | --- |
| `reports/ruff.json` | Ruff machine-readable findings |
| `reports/bandit.json` | Bandit security findings |
| `reports/pytest.xml` | Backend JUnit result |
| `reports/playwright.xml` | Browser JUnit result |
| `reports/coverage.xml` | Coverage XML |
| `reports/coverage-html/index.html` | Browsable line coverage |
| `reports/playwright/` | Failure traces and screenshots |

Generated reports are ignored by Git. Only `reports/README.md` is tracked.

**Hygiene checks**

- Verified virtual environments and generated reports are not tracked.
- Verified MyTemplate assets are tracked despite the broader public-static ignore
  rule.
- Scanned current tracked content and reachable Git history for common
  high-confidence credential and private-key patterns; none were found.
- Confirmed `.env`, `.env.local`, and production environment files are
  ignored.
- Confirmed `.env.local.sample` contains placeholder values only.

**Security follow-up**

No live secrets were found. The existing application still contains
development fallback strings for secret-related configuration. They are not
production credentials, but production should always supply `SECRET_KEY`,
`DATABASE_URL`, and any integration secrets through the environment.

## Final local verification

The final post-commit local `make ci` simulation produced:

| Check | Result |
| --- | --- |
| Ruff | 0 findings |
| Bandit | 0 findings |
| Backend Pytest | 103 passed, 0 failures, 0 errors |
| Playwright | 1 passed, 0 failures, 0 errors |
| Total tests | 104 passed |
| Terminal coverage | 86% |
| XML line rate | 87.46% |
| XML branch rate | 74.78% |

Some third-party deprecation and test-mode service warnings remain visible.
They do not fail the gate and were not broadly suppressed, because retaining
them makes pipeline output more transparent.

## Git history and delivery

| Commit | Purpose |
| --- | --- |
| `f213128` | Flask compatibility and QA dependencies |
| `8e12619` | MyTemplate rebrand |
| `86f6cca` | QA tests, reports, Make pipeline, and GitHub Actions |
| `0cd897d` | Assessment workflow and verification documentation |

The branch was pushed to the private origin and tracks:

```text
assessment/mytemplate...origin/assessment/mytemplate
```

Useful comparison commands:

```bash
git fetch upstream
git fetch origin

# Changes introduced by the assessment branch.
git diff --stat upstream/master...origin/assessment/mytemplate
git diff --name-status upstream/master...origin/assessment/mytemplate

# Assessment commits only.
git log --oneline upstream/master..origin/assessment/mytemplate
```

## Final documentation handoff

- This file is the canonical detailed assessment execution record.
- `README.md` remains the concise reviewer entry point for setup and checks.
- `reports/README.md` remains the artifact index.
- Two superseded draft documents were removed before the final documentation
  commit to keep the reviewer-facing material focused.
- No application, test, dependency, or pipeline file changed during the final
  documentation refresh.

Final verification commands:

```bash
git diff --check
make ci
git status --short --branch
git log -1 --oneline --decorate
```
