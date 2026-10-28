require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  test "should redirect /articles to root with 301 moved permanently" do
    get articles_url
    assert_response :moved_permanently
    assert_redirected_to root_path
  end

  test "should show article using slug" do
    article = Macron::Cms::Article.create!(title: "Friendly Article", name: "friendly-article")

    get article_url(article)
    assert_response :success
    assert_select "h1", "Friendly Article"
    assert_select "a[href=?]", root_path, text: /Back to articles/
  end

  test "should return 404 for unknown slug" do
    get article_url(id: "non-existent-slug")
    assert_response :not_found
  end
end
