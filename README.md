# MyTemplate

MyTemplate is a scaffold for starting new SaaS applications built using Python and Flask. It takes care of the boilerplate code (like User Registration, OAuth, Teams, and Billing), allowing you to focus on building your application. MyTemplate is built upon best practices for modern Flask applications.

## Features

| Features                              | Status                                       | Details                                                                                    |
| ------------------------------------- | -------------------------------------------- | ------------------------------------------------------------------------------------------ |
| User Authentication                   | ✅                                           | User Login, Registration, Forgot Password, Email Confirmation                              |
| OAuth Login                           | ✅                                           | Login or Register with Google, Twitter, Facebook, etc.                                     |
| Teams/Groups                          | ✅                                           | Multi user teams & groups (with Invite Emails)                                             |
| User Export & Deletion Request        | ✅                                           | Allows users to export their data (for GDPR compliance)                                    |
| API                                   | ✅                                           | API (with user tokens) users to access data                                                |
| Stripe Product Checkout               | ✅                                           | One time item purchases with credit cards and receipts (using Stripe)                      |
| Heroku/Docker Deployment              | ✅                                           | Deployment instructions for some platforms. Works on AWS & Google Cloud                    |
| Send Emails                           | ✅                                           | Send email notifications from the application                                              |
| Admin Dashboard                       | ✅                                           | Admin dashboard to edit data                                                               |
| File Uploads                          | ✅                                           | File uploads to cloud storage providers                                                    |
| Basic Test Suite                      | ✅                                           | Starting point for you to build out tests                                                  |
| VS Code Debugger & Editor             | ✅                                           | Configured to make you productive                                                          |
| Tested on Windows 10, OSX, and Ubuntu | ✅                                           | Using Python 3                                                                             |

## Setup

Usage of Python 3 is required. It can be installed [on Python.org](https://www.python.org/downloads/)

```bash
# Create env/, install development dependencies, and install Chromium.
make setup

./manage.py server # or `FLASK_APP=manage flask --debug run`
```

## AI Agent Guide

If you are using an AI coding agent, start with:

- `AGENTS.md` for repo-specific workflow and architecture guidance
- `documentation/AGENT_QUICKSTART.md` for copy-paste setup/test commands
- `make setup`, `make agent-smoke`, and `make ci` for standard agent checks

## Development

```
# Development
# If using a virtual env: source env/bin/activate
./manage.py resetdb # to seed data
FLASK_APP=manage flask --debug run

# Go to localhost:5000 in a browser and click on Login
# Login with the following credentials: "user@example.com" / "test"

# Production documentation in the repository.
```

## Testing

GitHub Actions runs the same quality pipeline used locally. To execute Ruff,
Bandit, backend tests with coverage, and the Chromium UI test:

```bash
make ci
```

Generated JUnit, coverage, Ruff, Bandit, and Playwright outputs are written to
`reports/`. GitHub Actions uploads that directory as the `quality-reports`
artifact. Run `make help` to see the individual setup and quality targets.

### Local Secrets

To configure OAuth login and Stripe billing in development, you will need to set some environment variables. See `.env.local.sample` for an example.

```bash
cp .env.local.sample .env.local
# Edit .env.local with your Stripe & Google test keys
source .env.local
FLASK_APP=manage flask --debug run
```

Application branding is centralized in `appname/services/branding.py`.

## Deployment

MyTemplate is not tied to a specific platform for deployment, but it works well on [Heroku](http://heroku.com) and [Dokku](http://dokku.viewdocs.io/dokku/) with minimal configuration.

It is also designed to work well on other cloud providers such as AWS, Google Cloud, and DigitalOcean.

Documentation is currently provided for installations on Dokku.

## Stripe Webhooks Locally

- Install the [Stripe CLI](https://stripe.com/docs/stripe-cli)
- Login to the Stripe CLI (`stripe login`)
- Run `stripe listen --forward-to localhost:5000/webhooks/stripe`
- Use the webhook secret and configure your app to use it (`export STRIPE_WEBHOOK_SECRET=whsec_...`)
- To replay an event in a seperate console: `stripe events resend evt_XYZ`

## Screenshots

| Screenshot                              | Name                                                    |
| --------------------------------------- | ------------------------------------------------------- |
| Login / Signup / OAuth / Password Reset | ![login](documentation/screenshots/login.png)           |
| Dashboard                               | ![Dashboard](documentation/screenshots/dashboard.png)   |
| Saas Subscription Billing + Console     | ![Billing](documentation/screenshots/billing.png)       |
| Teams                                   | ![Team](documentation/screenshots/team.png)             |
| GDPR/Legal                              | ![GDPR](documentation/screenshots/gdpr.png)             |
| Admin                                   | ![Admin](documentation/screenshots/admin.png)           |
| API Tokens                              | ![API](documentation/screenshots/api.png)               |
| Delayed Jobs                            | ![Jobs](documentation/screenshots/jobs.png)             |
| Emails                                  | ![Emails](documentation/screenshots/email.png)          |
| File Uploads                            | ![Files](documentation/screenshots/file-uploads.png)    |
| Stripe Customer Portal Integration      | ![Stripe](documentation/screenshots/stripe-console.png) |

## License and attribution

MyTemplate is based on the Ignite Flask starter project. The original license and attribution are retained in `LICENSE.md`.

## Credits

Design elements from [tabler](https://github.com/tabler/tabler) & Bootstrap 4.

Built off of [Flask Foundation](https://jackstouffer.github.io/Flask-Foundation/) and the [bootstrapy project](https://github.com/kirang89/bootstrapy)

### Extra Reading

Only building out an API using Flask?

- Use [create-flask-api](https://github.com/Sumukh/create-flask-api)

**Course: [Fullstack Flask: Build a SaaS using Python and Flask](https://www.newline.co/fullstack-flask/)**

Best practices List:

- [Larger Applications With Flask](http://flask.pocoo.org/docs/patterns/packages/).
- [Creating Websites With Flask](http://maximebf.com/blog/2012/10/building-websites-in-python-with-flask/)
- [Getting Bigger With Flask](http://maximebf.com/blog/2012/11/getting-bigger-with-flask/)
- [Miguel Grinberg's Blog](https://blog.miguelgrinberg.com/category/Python)
