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

    assert_includes html, '<select'
    assert_includes html, 'name="article_content[payload][level]"'
    assert_includes html, 'id="test_level"'
    assert_includes html, '(dropdown)'
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

  test "SUPPORTED_KINDS includes dropdown" do
    assert_includes Macron::Cms::FieldsHelper::SUPPORTED_KINDS, "dropdown"
  end
end
