require "test_helper"

class ArticlesApiTest < ActionDispatch::IntegrationTest
  setup do
    @original_key = Macron::Cms.configuration.api_key
    Macron::Cms.configuration.api_key = "test-secret-key"
    @auth_headers = {
      "Authorization" => "Bearer test-secret-key",
      "Content-Type" => "application/json"
    }

    # Ensure required content types exist
    Macron::Cms::Content.find_or_create_by!(name: "heading") do |c|
      c.fields = [
        { "name" => "title", "kind" => "string" },
        { "name" => "level", "kind" => "dropdown" },
        { "name" => "color", "kind" => "color" }
      ]
    end

    Macron::Cms::Content.find_or_create_by!(name: "markdown") do |c|
      c.fields = [ { "name" => "content", "kind" => "markdown" } ]
    end

    Macron::Cms::Content.find_or_create_by!(name: "image") do |c|
      c.fields = [
        { "name" => "upload", "kind" => "file" },
        { "name" => "size", "kind" => "dropdown" }
      ]
    end
  end

  teardown do
    Macron::Cms.configuration.api_key = @original_key
  end

  test "POST /cms/api/v1/articles creates article with nested content blocks" do
    payload = {
      article: {
        title: "Test Import Article",
        meta_title: "Test SEO Title",
        meta_description: "Test SEO Description"
      },
      content_blocks: [
        {
          content_type: "heading",
          payload: { title: "Introduction", level: "h2" }
        },
        {
          content_type: "markdown",
          payload: { content: "This is a **markdown** paragraph." }
        }
      ]
    }

    post "/cms/api/v1/articles", params: payload.to_json, headers: @auth_headers
    assert_response :created

    json = JSON.parse(response.body)
    assert_equal "Test Import Article", json["article"]["title"]
    assert_equal "test-import-article", json["article"]["slug"]
    assert_equal 2, json["content_blocks"].size
    assert_equal "heading", json["content_blocks"][0]["content_type"]
    assert_equal "Introduction", json["content_blocks"][0]["payload"]["title"]
    assert_equal "markdown", json["content_blocks"][1]["content_type"]
  end

  test "POST /cms/api/v1/articles with upsert: true updates existing article and replaces blocks" do
    article = Macron::Cms::Article.create!(title: "Existing Title", slug: "existing-slug")
    heading_type = Macron::Cms::Content.find_by!(name: "heading")
    article.article_contents.create!(content: heading_type, payload: { "title" => "Old Heading" })

    payload = {
      upsert: true,
      article: {
        slug: "existing-slug",
        title: "Updated Title",
        meta_description: "Updated Meta"
      },
      content_blocks: [
        {
          content_type: "markdown",
          payload: { content: "Replaced content body" }
        }
      ]
    }

    post "/cms/api/v1/articles", params: payload.to_json, headers: @auth_headers
    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal "Updated Title", json["article"]["title"]
    assert_equal 1, json["content_blocks"].size
    assert_equal "markdown", json["content_blocks"][0]["content_type"]
    assert_equal "Replaced content body", json["content_blocks"][0]["payload"]["content"]
  end

  test "POST /cms/api/v1/articles handles image block and falls back to remote URL on download failure" do
    payload = {
      article: {
        title: "Article With Image"
      },
      content_blocks: [
        {
          content_type: "image",
          payload: { size: "lg" },
          image_url: "https://example.invalid/unreachable-image.png"
        }
      ]
    }

    post "/cms/api/v1/articles", params: payload.to_json, headers: @auth_headers
    assert_response :created

    json = JSON.parse(response.body)
    block = json["content_blocks"].first
    assert_equal "image", block["content_type"]
    assert_equal "https://example.invalid/unreachable-image.png", block["payload"]["upload"]
  end

  test "POST /cms/api/v1/articles returns 422 if unknown content type is given" do
    payload = {
      article: { title: "Bad Type Article" },
      content_blocks: [
        { content_type: "non_existent_type", payload: {} }
      ]
    }

    post "/cms/api/v1/articles", params: payload.to_json, headers: @auth_headers
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_match(/Unknown content type: 'non_existent_type'/, json["errors"].first)
  end

  test "GET /cms/api/v1/articles/:id returns article and its blocks" do
    article = Macron::Cms::Article.create!(title: "Retrieve Me")
    get "/cms/api/v1/articles/#{article.slug}", headers: @auth_headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "Retrieve Me", json["article"]["title"]
    assert_nil json["article"]["featured_image"]
  end

  test "GET /cms/api/v1/articles/:id returns article with featured_image metadata when attached" do
    article = Macron::Cms::Article.create!(title: "Featured Article")
    image_type = Macron::Cms::Content.find_by!(name: "image")
    image_type.update!(featured_image: true)

    block = article.article_contents.create!(content: image_type, sort_order: 1)
    file = Rack::Test::UploadedFile.new(StringIO.new("img-data"), "image/png", original_filename: "cover.png")
    block.files.attach(file)

    get "/cms/api/v1/articles/#{article.slug}", headers: @auth_headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_not_nil json["article"]["featured_image"]
    assert_equal "cover.png", json["article"]["featured_image"]["filename"]
    assert_equal "image/png", json["article"]["featured_image"]["content_type"]
    assert_match %r{/rails/active_storage/blobs/}, json["article"]["featured_image"]["url"]
  end

  test "GET /cms/api/v1/articles/:id returns 404 for unknown article" do
    get "/cms/api/v1/articles/does-not-exist", headers: @auth_headers
    assert_response :not_found
  end

  test "POST and PATCH /cms/api/v1/articles supports custom published_at" do
    custom_time = "2024-03-15T10:30:00Z"
    payload = {
      article: {
        title: "API Date Article",
        published_at: custom_time
      }
    }

    post "/cms/api/v1/articles", params: payload.to_json, headers: @auth_headers
    assert_response :created

    json = JSON.parse(response.body)
    assert_equal Time.iso8601(custom_time), Time.iso8601(json["article"]["published_at"])

    article = Macron::Cms::Article.find_by!(title: "API Date Article")
    assert_equal Time.iso8601(custom_time), article.published_at

    # Update published_at
    updated_time = "2027-08-20T18:00:00Z"
    patch "/cms/api/v1/articles/#{article.slug}",
          params: { article: { published_at: updated_time } }.to_json,
          headers: @auth_headers
    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal Time.iso8601(updated_time), Time.iso8601(json["article"]["published_at"])
    assert_equal Time.iso8601(updated_time), article.reload.published_at
  end
end
