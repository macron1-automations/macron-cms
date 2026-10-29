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

  test "should render ordered content block widgets on public show page" do
    article = Macron::Cms::Article.create!(title: "Rich Content Article", name: "rich-content-article")
    heading_type = Macron::Cms::Content.find_or_create_by!(name: "heading") do |c|
      c.fields = [ { "name" => "title", "kind" => "string" }, { "name" => "level", "kind" => "string" } ]
    end
    paragraph_type = Macron::Cms::Content.find_or_create_by!(name: "paragraph") do |c|
      c.fields = [ { "name" => "content", "kind" => "text" } ]
    end
    quote_type = Macron::Cms::Content.find_or_create_by!(name: "three_js_quote") do |c|
      c.fields = [ { "name" => "text", "kind" => "string" }, { "name" => "color", "kind" => "color" } ]
    end

    Macron::Cms::ArticleContent.create!(
      article: article,
      content: heading_type,
      sort_order: 1,
      payload: { "title" => "Subheading Title", "level" => "h2" }
    )
    Macron::Cms::ArticleContent.create!(
      article: article,
      content: paragraph_type,
      sort_order: 2,
      payload: { "content" => "This is a body paragraph in the article." }
    )
    Macron::Cms::ArticleContent.create!(
      article: article,
      content: quote_type,
      sort_order: 3,
      payload: { "text" => "Make it work, make it right, make it fast.", "color" => "#2563eb" }
    )

    get article_url(article)
    assert_response :success
    assert_select "h2", text: "Subheading Title"
    assert_select "p", text: "This is a body paragraph in the article."
    assert_select "figure[data-three-js-quote-card] div[data-three-js-quote-mount][data-quote-text='Make it work, make it right, make it fast.'][data-quote-color='#2563eb']"
    assert_select "script[src*='turbo']"
    assert_select "script[src*='react_bundle']"
    assert_select "script[src*='three_text_bundle']"
    assert_select "script[src*='three_js_quote']"
  end
end
