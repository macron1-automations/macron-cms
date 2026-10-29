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

  test "paragraph component renders formatted paragraph text" do
    render_inline(Widgets::ParagraphComponent.new(payload: { "content" => "Lorem ipsum dolor sit amet." }))
    assert_selector "p", text: "Lorem ipsum dolor sit amet."
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
end
