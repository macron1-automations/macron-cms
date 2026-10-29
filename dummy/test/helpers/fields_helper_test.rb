require "test_helper"

class FieldsHelperTest < ActionView::TestCase
  include Macron::Cms::FieldsHelper

  test "cms_render_field renders dropdown with options and selected value" do
    field_def = {
      "name" => "level",
      "kind" => "dropdown",
      "options" => [
        { "name" => "Heading 1", "value" => "h1" },
        { "name" => "Heading 2", "value" => "h2" },
        { "name" => "Heading 3", "value" => "h3" }
      ]
    }

    html = cms_render_field(field_def, value: "h2", input_name: "article_content[payload][level]", input_id: "test_level")

    assert_includes html, "<select"
    assert_includes html, 'name="article_content[payload][level]"'
    assert_includes html, 'id="test_level"'
    assert_includes html, "(dropdown)"
    assert_includes html, '<option value="">Select level...</option>'
    assert_includes html, '<option value="h1">Heading 1</option>'
    assert_includes html, '<option value="h2" selected>Heading 2</option>'
    assert_includes html, '<option value="h3">Heading 3</option>'
  end

  test "cms_render_field renders dropdown with string array options" do
    field_def = {
      "name" => "color",
      "kind" => "dropdown",
      "options" => %w[red green blue]
    }

    html = cms_render_field(field_def, value: "green")

    assert_includes html, '<option value="red">red</option>'
    assert_includes html, '<option value="green" selected>green</option>'
    assert_includes html, '<option value="blue">blue</option>'
  end

  test "SUPPORTED_KINDS includes dropdown and file" do
    assert_includes Macron::Cms::FieldsHelper::SUPPORTED_KINDS, "dropdown"
    assert_includes Macron::Cms::FieldsHelper::SUPPORTED_KINDS, "file"
    assert_includes Macron::Cms::FieldsHelper::SUPPORTED_KINDS, "color"
    assert_includes Macron::Cms::FieldsHelper::SUPPORTED_KINDS, "markdown"
    assert_includes Macron::Cms::FieldsHelper::SUPPORTED_KINDS, "json"
  end

  test "cms_render_field renders markdown editor textarea with data-cms-editor" do
    field_def = {
      "name" => "content",
      "kind" => "markdown"
    }

    html = cms_render_field(field_def, value: "# Hello World", input_name: "article_content[payload][content]", input_id: "test_content")
    assert_includes html, "<textarea"
    assert_includes html, 'name="article_content[payload][content]"'
    assert_includes html, 'id="test_content"'
    assert_includes html, 'data-cms-editor="markdown"'
    assert_includes html, "(markdown)"
    assert_includes html, "CodeMirror"
    assert_includes html, "# Hello World"
  end

  test "cms_render_field renders json editor textarea with data-cms-editor" do
    field_def = {
      "name" => "settings",
      "kind" => "json"
    }

    html = cms_render_field(field_def, value: '{"key": "value"}', input_name: "article_content[payload][settings]", input_id: "test_settings")
    assert_includes html, "<textarea"
    assert_includes html, 'name="article_content[payload][settings]"'
    assert_includes html, 'id="test_settings"'
    assert_includes html, 'data-cms-editor="json"'
    assert_includes html, "(json)"
    assert_includes html, "CodeMirror"
    assert_includes html, "{&quot;key&quot;: &quot;value&quot;}"
  end

  test "cms_render_field renders color picker with reset button" do
    field_def = {
      "name" => "color",
      "kind" => "color"
    }

    # Empty value
    html = cms_render_field(field_def, value: nil, input_name: "article_content[payload][color]", input_id: "test_color")
    assert_includes html, 'type="hidden"'
    assert_includes html, 'name="article_content[payload][color]"'
    assert_includes html, 'id="test_color"'
    assert_includes html, 'type="color"'
    assert_includes html, 'id="test_color_picker"'
    assert_includes html, "(color)"
    assert_includes html, "Reset to default"
    assert_includes html, "Default (theme color)"

    # With existing color value
    html_with_color = cms_render_field(field_def, value: "#2563eb", input_name: "article_content[payload][color]", input_id: "test_color")
    assert_includes html_with_color, 'value="#2563eb"'
    assert_includes html_with_color, "#2563eb"
  end

  test "cms_render_field renders file input with label and optional current value" do
    field_def = {
      "name" => "upload",
      "kind" => "file"
    }

    # Empty value
    html = cms_render_field(field_def, value: nil, input_name: "article_content[payload][upload]", input_id: "test_upload")
    assert_includes html, 'type="file"'
    assert_includes html, 'name="article_content[payload][upload]"'
    assert_includes html, 'id="test_upload"'
    assert_includes html, "(file)"

    # With existing filename
    html_with_file = cms_render_field(field_def, value: "hero.jpg", input_name: "article_content[payload][upload]", input_id: "test_upload")
    assert_includes html_with_file, "hero.jpg"
    assert_includes html_with_file, "Current file"
    assert_includes html_with_file, "Choose a new file to replace the existing one"
  end

  test "cms_render_markdown renders markdown content to formatted html" do
    markdown = "# Main Title\n\nThis is **bold** text with a [link](https://example.com) and `inline code`.\n\n- Item 1\n- Item 2"
    result = cms_render_markdown(markdown)

    assert_includes result, "<h1>Main Title</h1>"
    assert_includes result, "<strong>bold</strong>"
    assert_includes result, '<a href="https://example.com">link</a>'
    assert_includes result, "<code>inline code</code>"
    assert_includes result, "<ul>"
    assert_includes result, "<li>Item 1</li>"
  end

  test "cms_render_markdown returns empty string for blank input" do
    assert_equal "", cms_render_markdown(nil)
    assert_equal "", cms_render_markdown("")
    assert_equal "", cms_render_markdown("   ")
  end

  test "cms_render_markdown sanitizes malicious html script tags" do
    malicious = "# Heading\n\n<script>alert('xss');</script>\n\n<p onclick=\"steal()\">Paragraph</p>"
    result = cms_render_markdown(malicious)

    assert_includes result, "<h1>Heading</h1>"
    assert_not_includes result, "<script>"
    assert_not_includes result, "</script>"
    assert_not_includes result, "onclick"
    assert_includes result, "<p>Paragraph</p>"
  end
end
