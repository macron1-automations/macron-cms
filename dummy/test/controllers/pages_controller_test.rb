require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get index and list articles" do
    Macron::Cms::Article.create!(title: "Test Article")

    get root_url
    assert_response :success
    assert_select "h1", "Articles"
    assert_select "li", text: "Test Article"
  end
end
