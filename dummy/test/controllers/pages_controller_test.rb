require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get index and list articles" do
    article = Macron::Cms::Article.create!(title: "Test Article", name: "test-article")

    get root_url
    assert_response :success
    assert_select "h1", "Articles"
    assert_select "li", text: /Test Article/
    assert_select "a[href=?]", article_path(article)
  end
end
