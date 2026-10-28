require "test_helper"

class ContentHelperTest < ActionView::TestCase
  include Macron::Cms::ContentHelper
  test "cms_render_article_contents renders widgets in sort_order" do
    article = Macron::Cms::Article.create!(title: "Render Test Article", name: "render-test-article")
    heading_type = Macron::Cms::Content.create!(
      name: "heading",
      fields: [
        { "name" => "title", "kind" => "string" },
        { "name" => "level", "kind" => "string" }
      ]
    )
    paragraph_type = Macron::Cms::Content.create!(
      name: "paragraph",
      fields: [ { "name" => "content", "kind" => "text" } ]
    )

    Macron::Cms::ArticleContent.create!(
      article: article,
      content: paragraph_type,
      sort_order: 2,
      payload: { "content" => "Second paragraph text." }
    )
    Macron::Cms::ArticleContent.create!(
      article: article,
      content: heading_type,
      sort_order: 1,
      payload: { "title" => "First Heading", "level" => "h2" }
    )

    rendered = cms_render_article_contents(article)
    assert_includes rendered, "<h2"
    assert_includes rendered, "First Heading"
    assert_includes rendered, "<p"
    assert_includes rendered, "Second paragraph text."

    # Verify heading comes before paragraph in output
    heading_pos = rendered.index("First Heading")
    para_pos = rendered.index("Second paragraph text.")
    assert heading_pos < para_pos
  end

  test "cms_render_widget raises MissingWidgetError for missing widget component" do
    article = Macron::Cms::Article.create!(title: "Missing Widget Article", name: "missing-widget-article")
    mystery_type = Macron::Cms::Content.create!(name: "mystery_box", fields: [])
    ac = Macron::Cms::ArticleContent.create!(article: article, content: mystery_type, payload: {})

    assert_raises Macron::Cms::MissingWidgetError do
      cms_render_widget(ac)
    end
  end

  test "cms_render_article_contents returns empty string when article is nil or has no contents" do
    assert_equal "", cms_render_article_contents(nil)

    article = Macron::Cms::Article.create!(title: "Empty Article", name: "empty-article")
    assert_equal "", cms_render_article_contents(article)
  end
end
