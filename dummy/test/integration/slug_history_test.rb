require "test_helper"

class SlugHistoryTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @original_key = Macron::Cms.configuration.api_key
    Macron::Cms.configuration.api_key = "test-secret-key"
    @auth_headers = {
      "Authorization" => "Bearer test-secret-key",
      "Content-Type" => "application/json"
    }
  end

  teardown do
    Macron::Cms.configuration.api_key = @original_key
  end

  test "recording previous slugs in friendly_id_slugs and public 301 canonical redirects" do
    article = Macron::Cms::Article.create!(title: "Initial Launch Post", name: "initial-launch-post")
    assert_equal "initial-launch-post", article.slug

    # Verify initial slug is recorded
    assert article.slugs.where(slug: "initial-launch-post").exists?

    # Public show works with original slug
    get "/articles/initial-launch-post"
    assert_response :success
    assert_select "h1", "Initial Launch Post"

    # Update slug to a new value
    article.update!(slug: "renamed-launch-post")
    assert_equal "renamed-launch-post", article.slug

    # FriendlyId history should contain both old and new slugs
    assert article.slugs.where(slug: "initial-launch-post").exists?
    assert article.slugs.where(slug: "renamed-launch-post").exists?

    # Public request to old slug issues 301 Moved Permanently redirect to new slug
    get "/articles/initial-launch-post"
    assert_response :moved_permanently
    assert_redirected_to "/articles/renamed-launch-post"

    # Query parameters are preserved across the 301 redirect
    get "/articles/initial-launch-post?ref=newsletter"
    assert_response :moved_permanently
    assert_redirected_to "/articles/renamed-launch-post?ref=newsletter"

    # Following the redirect reaches the new slug with 200 OK
    follow_redirect!
    assert_response :success
    assert_select "h1", "Initial Launch Post"

    # Public request to new slug directly renders 200 OK without redirect
    get "/articles/renamed-launch-post"
    assert_response :success

    # Completely non-existent slug returns 404
    get "/articles/non-existent-slug"
    assert_response :not_found
  end

  test "cms admin does not 301 redirect when accessed with historical slug" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "CMS Admin History Test", name: "admin-history-initial")

    article.update!(slug: "admin-history-updated")

    # Accessing CMS admin show with the old slug renders 200 OK directly
    get "/cms/articles/admin-history-initial"
    assert_response :success
    assert_select "h1", /CMS Admin History Test/

    # Accessing CMS admin edit with the old slug renders 200 OK directly
    get "/cms/articles/admin-history-initial/edit"
    assert_response :success
  end

  test "cms admin edit form displays slug in Identifier Name field and updates slug" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Form Edit Test", name: "original-fixed-name", slug: "original-form-slug")

    get "/cms/articles/#{article.slug}/edit"
    assert_response :success
    assert_select "label[for='article_slug']", "Identifier Name"
    assert_select "input#article_slug[name='article[slug]'][value='original-form-slug']"

    patch "/cms/articles/#{article.slug}", params: {
      article: {
        slug: "brand-new-edited-slug"
      }
    }

    assert_redirected_to "/cms/articles/brand-new-edited-slug"
    article.reload
    assert_equal "brand-new-edited-slug", article.slug
    assert_equal "original-fixed-name", article.name
    assert article.slugs.where(slug: "original-form-slug").exists?

    # Verify public 301 redirect from old slug to new slug
    get "/articles/original-form-slug"
    assert_response :moved_permanently
    assert_redirected_to "/articles/brand-new-edited-slug"
  end

  test "cms api returns 404 for historical slugs but 200 for current slug or numeric ID" do
    article = Macron::Cms::Article.create!(title: "API History Strictness", name: "api-slug-v1")
    article.update!(slug: "api-slug-v2")

    # Old slug in API returns 404 Not Found
    get "/cms/api/v1/articles/api-slug-v1", headers: @auth_headers
    assert_response :not_found
    json = JSON.parse(response.body)
    assert_equal "Article not found", json["error"]

    # Current slug returns 200 OK
    get "/cms/api/v1/articles/api-slug-v2", headers: @auth_headers
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal article.id, json.dig("article", "id")
    assert_equal "api-slug-v2", json.dig("article", "slug")

    # Numeric ID returns 200 OK
    get "/cms/api/v1/articles/#{article.id}", headers: @auth_headers
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal article.id, json.dig("article", "id")
  end
end
