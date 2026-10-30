require "test_helper"

class ContentHelperTest < ActionView::TestCase
  include Macron::Cms::ContentHelper
  test "cms_render_article_contents renders widgets in sort_order" do
    article = Macron::Cms::Article.create!(title: "Render Test Article")
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
    article = Macron::Cms::Article.create!(title: "Missing Widget Article")
    mystery_type = Macron::Cms::Content.create!(name: "mystery_box", fields: [])
    ac = Macron::Cms::ArticleContent.create!(article: article, content: mystery_type, payload: {})

    assert_raises Macron::Cms::MissingWidgetError do
      cms_render_widget(ac)
    end
  end

  test "cms_render_article_contents returns empty string when article is nil or has no contents" do
    assert_equal "", cms_render_article_contents(nil)

    article = Macron::Cms::Article.create!(title: "Empty Article")
    assert_equal "", cms_render_article_contents(article)
  end

  test "cms_render_article_contents renders image and embed widgets" do
    article = Macron::Cms::Article.create!(title: "Media Article")
    image_type = Macron::Cms::Content.create!(name: "image", fields: [ { "name" => "upload", "kind" => "file" } ])
    embed_type = Macron::Cms::Content.create!(name: "embed", fields: [ { "name" => "upload", "kind" => "file" } ])

    image_block = Macron::Cms::ArticleContent.create!(article: article, content: image_type, sort_order: 1)
    image_file = Rack::Test::UploadedFile.new(StringIO.new("fake image"), "image/png", original_filename: "illustration.png")
    image_block.files.attach(image_file)

    embed_block = Macron::Cms::ArticleContent.create!(article: article, content: embed_type, sort_order: 2)
    embed_file = Rack::Test::UploadedFile.new(StringIO.new("<p>Embed content</p>"), "text/html", original_filename: "app.html")
    embed_block.files.attach(embed_file)

    rendered = cms_render_article_contents(article)
    assert_includes rendered, "<figure"
    assert_includes rendered, "<img"
    assert_includes rendered, "<iframe"
    assert_includes rendered, "Embed content"
  end

  test "cms_article_background_style returns empty string when article is nil or has no background styles" do
    assert_equal "", cms_article_background_style(nil)

    article = Macron::Cms::Article.create!(title: "Plain Article")
    assert_equal "", cms_article_background_style(article)
  end

  test "cms_article_background_style includes background-color when set" do
    article = Macron::Cms::Article.create!(
      title: "Color Article",
      background_color: "#3b82f6"
    )

    style = cms_article_background_style(article)
    assert_equal "background-color: #3b82f6;", style
  end

  test "cms_article_background_style includes full background properties when image is attached" do
    article = Macron::Cms::Article.create!(
      title: "Image Article",
      background_color: "#0f172a",
      background_options: {
        "repeat" => "repeat",
        "size" => "auto",
        "position" => "top",
        "attachment" => "fixed"
      }
    )
    file = Rack::Test::UploadedFile.new(StringIO.new("dummy bg data"), "image/png", original_filename: "pattern.png")
    article.background_image.attach(file)

    style = cms_article_background_style(article)
    assert_includes style, "background-color: #0f172a;"
    assert_includes style, "background-image: url("
    assert_includes style, "background-repeat: repeat;"
    assert_includes style, "background-size: auto;"
    assert_includes style, "background-position: top;"
    assert_includes style, "background-attachment: fixed;"
  end

  test "cms_article_background_style includes text color when set" do
    article = Macron::Cms::Article.create!(
      title: "Text Styled Article",
      text_color: "#e2e8f0"
    )

    style = cms_article_background_style(article)
    assert_includes style, "color: #e2e8f0;"
  end

  test "cms_render_article_contents renders widgets with attached files without N+1 queries" do
    article = Macron::Cms::Article.create!(title: "Widgets N+1 Article")
    image_type = Macron::Cms::Content.find_or_create_by!(name: "image") do |c|
      c.fields = [ { "name" => "upload", "kind" => "file" }, { "name" => "size", "kind" => "dropdown" } ]
    end

    5.times do |i|
      ac = Macron::Cms::ArticleContent.create!(article: article, content: image_type, sort_order: i + 1, payload: { "size" => "md" })
      ac.files.attach(Rack::Test::UploadedFile.new(StringIO.new("widget data #{i}"), "image/png", original_filename: "widget_#{i}.png"))
    end

    rendered = nil
    queries = count_queries do
      rendered = cms_render_article_contents(article)
    end

    assert_not_empty rendered
    # O(1) constant queries: ArticleContent + Attachment batch IN + Blob batch IN + VariantRecord batch IN + Content batch IN
    assert_operator queries, :<=, 6, "Expected cms_render_article_contents to execute constant batch queries, got #{queries}"
  end
end
