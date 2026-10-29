require "test_helper"

class ContentTypesApiTest < ActionDispatch::IntegrationTest
  setup do
    @original_key = Macron::Cms.configuration.api_key
    Macron::Cms.configuration.api_key = "test-secret-key"

    Macron::Cms::Content.find_or_create_by!(name: "heading") do |c|
      c.fields = [
        { "name" => "title", "kind" => "string" },
        { "name" => "level", "kind" => "dropdown" }
      ]
    end

    Macron::Cms::Content.find_or_create_by!(name: "markdown") do |c|
      c.fields = [ { "name" => "content", "kind" => "markdown" } ]
    end
  end

  teardown do
    Macron::Cms.configuration.api_key = @original_key
  end

  test "returns 401 unauthorized when API key is missing or invalid" do
    get "/cms/api/v1/content_types"
    assert_response :unauthorized
    assert_equal "Unauthorized. Missing or invalid API key.", JSON.parse(response.body)["error"]

    get "/cms/api/v1/content_types", headers: { "Authorization" => "Bearer wrong-key" }
    assert_response :unauthorized
  end

  test "returns content types when valid Bearer token is provided" do
    get "/cms/api/v1/content_types", headers: { "Authorization" => "Bearer test-secret-key" }
    assert_response :success

    json = JSON.parse(response.body)
    assert json.key?("content_types")
    names = json["content_types"].map { |ct| ct["name"] }
    assert_includes names, "markdown"
    assert_includes names, "heading"
  end

  test "supports X-API-Key header" do
    get "/cms/api/v1/content_types", headers: { "X-API-Key" => "test-secret-key" }
    assert_response :success
  end
end
