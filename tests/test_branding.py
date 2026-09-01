create_user = False


def test_landing_page_displays_mytemplate_branding(testapp):
    """The public landing page renders the new name and static assets."""
    response = testapp.get('/')
    page = response.get_data(as_text=True)

    assert response.status_code == 200
    assert '<title>MyTemplate</title>' in page
    assert 'alt="MyTemplate"' in page
    assert '/static/public/mytemplate/mytemplate-icon.svg' in page
    assert '/static/public/mytemplate/demo-1.png' in page
