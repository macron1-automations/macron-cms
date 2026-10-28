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
    assert_select "title", "Friendly Article"
    assert_select "link[rel='canonical'][href=?]", article_url(article)
    assert_select "meta[property='og:title'][content=?]", "Friendly Article"
    assert_select "meta[property='og:url'][content=?]", article_url(article)
    assert_select "meta[name='description']", count: 0
  end

  test "should render custom SEO metadata when article defines meta_title and meta_description" do
    article = Macron::Cms::Article.create!(
      title: "Friendly Article",
      name: "seo-article",
      meta_title: "Custom Title For Search",
      meta_description: "Custom Description For Search Snippets"
    )

    get article_url(article)
    assert_response :success
    assert_select "title", "Custom Title For Search"
    assert_select "meta[name='description'][content=?]", "Custom Description For Search Snippets"
    assert_select "link[rel='canonical'][href=?]", article_url(article)
    assert_select "meta[property='og:title'][content=?]", "Custom Title For Search"
    assert_select "meta[property='og:description'][content=?]", "Custom Description For Search Snippets"
    assert_select "meta[property='og:url'][content=?]", article_url(article)
  end

  test "should return 404 for unknown slug" do
    get article_url(id: "non-existent-slug")
    assert_response :not_found
  end
end
