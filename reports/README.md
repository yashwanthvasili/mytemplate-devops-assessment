# Generated QA reports

The quality pipeline writes its reviewable output here:

- `pytest.xml` - JUnit backend test results.
- `playwright.xml` - JUnit Playwright UI test results.
- `coverage.xml` - machine-readable coverage.
- `coverage-html/index.html` - browsable line-by-line coverage.
- `ruff.json` - machine-readable static-analysis results.
- `bandit.json` - machine-readable security-scan results.
- `playwright/` - traces and screenshots retained when a UI test fails.

Generated outputs are intentionally ignored by Git. The local build recreates
them, and `.github/workflows/flask-pytest.yml` uploads the directory as the
`quality-reports` artifact after every CI run, including failed runs.
