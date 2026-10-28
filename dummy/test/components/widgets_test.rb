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
end
