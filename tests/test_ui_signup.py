from threading import Thread

import pytest
from playwright.sync_api import Page, expect
from werkzeug.serving import make_server

from appname import create_app
from appname.settings import TestConfig


class UITestConfig(TestConfig):
    DEBUG_TB_ENABLED = False


@pytest.fixture()
def live_server_url():
    """Run the Flask test app on an available local port."""
    app = create_app(UITestConfig)
    server = make_server('127.0.0.1', 0, app, threaded=True)
    server_thread = Thread(target=server.serve_forever, daemon=True)
    server_thread.start()

    try:
        yield f'http://127.0.0.1:{server.server_port}'
    finally:
        server.shutdown()
        server.server_close()
        server_thread.join(timeout=5)


def test_visitor_can_open_mytemplate_signup(page: Page, live_server_url):
    """A visitor can navigate from the landing page to the signup form."""
    response = page.goto(live_server_url)

    assert response is not None
    assert response.ok
    expect(page).to_have_title('MyTemplate')

    page.get_by_role('link', name='Demo').first.click()

    expect(page).to_have_url(f'{live_server_url}/signup')
    expect(page).to_have_title('MyTemplate Signup')
    expect(page.get_by_text('Sign up for MyTemplate', exact=True)).to_be_visible()
    expect(page.get_by_role('button', name='Sign Up')).to_be_visible()

    logo = page.get_by_role('img', name='MyTemplate logo')
    expect(logo).to_be_visible()
    assert logo.evaluate('(image) => image.complete && image.naturalWidth > 0')
