require "test_helper"

class WidgetsTest < ViewComponent::TestCase
  test "widget component exposes payload, fields and dynamic method readers" do
    comp = Macron::Cms::WidgetComponent.new(
      payload: { "title" => "Widget Title", "score" => 42 },
      fields: [ { "name" => "title", "kind" => "string" }, { "name" => "score", "kind" => "integer" } ]
    )

    assert_equal "Widget Title", comp.title
    assert_equal 42, comp.score
    assert_equal "Widget Title", comp.field_value("title")
    assert_equal({ "title" => "Widget Title", "score" => 42 }, comp.payload)
  end

  test "heading component normalizes level and renders appropriate tag" do
    render_inline(Widgets::HeadingComponent.new(payload: { "title" => "Section 1", "level" => "h1" }))
    assert_selector "h1", text: "Section 1"

    render_inline(Widgets::HeadingComponent.new(payload: { "title" => "Section 3", "level" => "3" }))
    assert_selector "h3", text: "Section 3"

    render_inline(Widgets::HeadingComponent.new(payload: { "title" => "Default Level", "level" => "" }))
    assert_selector "h2", text: "Default Level"
  end

  test "heading component defaults to text-zinc-900 when color is omitted or blank" do
    render_inline(Widgets::HeadingComponent.new(payload: { "title" => "Default Color Heading", "level" => "h2" }))
    assert_selector "h2.text-zinc-900", text: "Default Color Heading"
    assert_no_selector "h2[style]"

    render_inline(Widgets::HeadingComponent.new(payload: { "title" => "Blank Color Heading", "level" => "h2", "color" => "" }))
    assert_selector "h2.text-zinc-900", text: "Blank Color Heading"
    assert_no_selector "h2[style]"
  end

  test "heading component applies custom inline color and strips text-zinc-900 class" do
    rendered = render_inline(Widgets::HeadingComponent.new(payload: { "title" => "Blue Heading", "level" => "h1", "color" => "#2563eb" }))
    assert_selector "h1[style='color: #2563eb;']", text: "Blue Heading"
    assert_no_selector "h1.text-zinc-900"
    assert_includes rendered.to_html, "text-3xl"
  end

  test "heading component adopts article text_color as fallback and allows widget color override" do
    article = Macron::Cms::Article.create!(title: "Themed Art", text_color: "#10b981")
    heading_type = Macron::Cms::Content.create!(name: "heading", fields: [])
    ac = Macron::Cms::ArticleContent.create!(article: article, content: heading_type)

    # Fallback to article text_color when heading color is blank
    render_inline(Widgets::HeadingComponent.new(article_content: ac, payload: { "title" => "Green Heading", "level" => "h2" }))
    assert_selector "h2[style='color: #10b981;']", text: "Green Heading"
    assert_no_selector "h2.text-zinc-900"

    # Specific heading color overrides article text_color
    render_inline(Widgets::HeadingComponent.new(article_content: ac, payload: { "title" => "Red Heading", "level" => "h2", "color" => "#ef4444" }))
    assert_selector "h2[style='color: #ef4444;']", text: "Red Heading"
    assert_no_selector "h2[style='color: #10b981;']"
    assert_no_selector "h2.text-zinc-900"
  end

  test "paragraph component renders formatted paragraph text" do
    render_inline(Widgets::ParagraphComponent.new(payload: { "content" => "Lorem ipsum dolor sit amet." }))
    assert_selector "p.text-zinc-700", text: "Lorem ipsum dolor sit amet."
    assert_no_selector "p[style]"
  end

  test "paragraph component applies article text_color when set" do
    article = Macron::Cms::Article.create!(title: "Themed Para Art", text_color: "#6366f1")
    para_type = Macron::Cms::Content.create!(name: "paragraph", fields: [])
    ac = Macron::Cms::ArticleContent.create!(article: article, content: para_type)

    render_inline(Widgets::ParagraphComponent.new(article_content: ac, payload: { "content" => "Custom color paragraph." }))
    assert_selector "p[style='color: #6366f1;']", text: "Custom color paragraph."
    assert_no_selector "p.text-zinc-700"
  end

  test "image component renders image tag when file is attached" do
    article = Macron::Cms::Article.create!(title: "Img Article", name: "img-article")
    content = Macron::Cms::Content.create!(name: "image", fields: [ { "name" => "upload", "kind" => "file" } ])
    ac = Macron::Cms::ArticleContent.create!(article: article, content: content)
    file = Rack::Test::UploadedFile.new(StringIO.new("img content"), "image/png", original_filename: "photo.png")
    ac.files.attach(file)

    render_inline(Widgets::ImageComponent.new(article_content: ac, payload: ac.payload))
    assert_selector "figure"
    assert_selector "img[alt='Article image']"
  end

  test "image component does not render when no upload exists" do
    rendered = render_inline(Widgets::ImageComponent.new(payload: {}))
    assert_empty rendered.to_html.strip
  end

  test "embed component renders iframe with srcdoc when html file is attached" do
    article = Macron::Cms::Article.create!(title: "Embed Article", name: "embed-article")
    content = Macron::Cms::Content.create!(name: "embed", fields: [ { "name" => "upload", "kind" => "file" } ])
    ac = Macron::Cms::ArticleContent.create!(article: article, content: content)
    file = Rack::Test::UploadedFile.new(StringIO.new("<h1>Interactive chart</h1>"), "text/html", original_filename: "chart.html")
    ac.files.attach(file)

    rendered = render_inline(Widgets::EmbedComponent.new(article_content: ac, payload: ac.payload))
    assert_selector "iframe[title='Embedded HTML content']"
    assert_selector "iframe[sandbox='allow-scripts allow-same-origin allow-popups']"
    assert_includes rendered.to_html, "<h1>Interactive chart</h1>"
  end

  test "embed component does not render when no upload exists" do
    rendered = render_inline(Widgets::EmbedComponent.new(payload: {}))
    assert_empty rendered.to_html.strip
  end

  test "image component applies responsive sizing classes and defaults to md" do
    article = Macron::Cms::Article.create!(title: "Img Size Article", name: "img-size-article")
    content = Macron::Cms::Content.create!(name: "image", fields: [ { "name" => "upload", "kind" => "file" }, { "name" => "size", "kind" => "dropdown" } ])
    ac = Macron::Cms::ArticleContent.create!(article: article, content: content)
    file = Rack::Test::UploadedFile.new(StringIO.new("img"), "image/png", original_filename: "photo.png")
    ac.files.attach(file)

    # Default (unspecified or nil size) -> w-full sm:w-1/2 mx-auto
    render_inline(Widgets::ImageComponent.new(article_content: ac, payload: {}))
    assert_selector "figure.w-full.sm\\:w-1\\/2.mx-auto"

    # Small size -> w-full sm:w-1/3 mx-auto
    render_inline(Widgets::ImageComponent.new(article_content: ac, payload: { "size" => "sm" }))
    assert_selector "figure.w-full.sm\\:w-1\\/3.mx-auto"

    # Large size -> w-full sm:w-3/4 mx-auto
    render_inline(Widgets::ImageComponent.new(article_content: ac, payload: { "size" => "lg" }))
    assert_selector "figure.w-full.sm\\:w-3\\/4.mx-auto"

    # Full size -> w-full
    render_inline(Widgets::ImageComponent.new(article_content: ac, payload: { "size" => "full" }))
    assert_selector "figure.w-full"
  end

  test "embed component applies responsive sizing classes and defaults to md" do
    article = Macron::Cms::Article.create!(title: "Embed Size Article", name: "embed-size-article")
    content = Macron::Cms::Content.create!(name: "embed", fields: [ { "name" => "upload", "kind" => "file" }, { "name" => "size", "kind" => "dropdown" } ])
    ac = Macron::Cms::ArticleContent.create!(article: article, content: content)
    file = Rack::Test::UploadedFile.new(StringIO.new("<b>chart</b>"), "text/html", original_filename: "chart.html")
    ac.files.attach(file)

    # Default (unspecified size) -> w-full sm:w-1/2 mx-auto
    render_inline(Widgets::EmbedComponent.new(article_content: ac, payload: {}))
    assert_selector "div.w-full.sm\\:w-1\\/2.mx-auto"

    # Small size -> w-full sm:w-1/3 mx-auto
    render_inline(Widgets::EmbedComponent.new(article_content: ac, payload: { "size" => "sm" }))
    assert_selector "div.w-full.sm\\:w-1\\/3.mx-auto"

    # Large size -> w-full sm:w-3/4 mx-auto
    render_inline(Widgets::EmbedComponent.new(article_content: ac, payload: { "size" => "lg" }))
    assert_selector "div.w-full.sm\\:w-3\\/4.mx-auto"

    # Full size -> w-full
    render_inline(Widgets::EmbedComponent.new(article_content: ac, payload: { "size" => "full" }))
    assert_selector "div.w-full"
  end
end
