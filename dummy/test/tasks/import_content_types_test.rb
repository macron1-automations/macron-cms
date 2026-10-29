require "test_helper"
require "rake"

class ImportContentTypesTaskTest < ActiveSupport::TestCase
  setup do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rails.application.load_tasks
  end

  def heading_expected_fields
    [
      { "name" => "title", "kind" => "string" },
      {
        "name" => "level",
        "kind" => "dropdown",
        "options" => [
          { "name" => "Heading 1", "value" => "h1" },
          { "name" => "Heading 2", "value" => "h2" },
          { "name" => "Heading 3", "value" => "h3" },
          { "name" => "Heading 4", "value" => "h4" },
          { "name" => "Heading 5", "value" => "h5" },
          { "name" => "Heading 6", "value" => "h6" }
        ]
      },
      { "name" => "color", "kind" => "color" }
    ]
  end

  def media_expected_fields
    [
      { "name" => "upload", "kind" => "file" },
      {
        "name" => "size",
        "kind" => "dropdown",
        "options" => [
          { "name" => "Small (33%)", "value" => "sm" },
          { "name" => "Medium (50%)", "value" => "md" },
          { "name" => "Large (75%)", "value" => "lg" },
          { "name" => "Full Width (100%)", "value" => "full" }
        ]
      }
    ]
  end

  test "imports heading content type from yml" do
    Rake::Task["macron:cms:import_content_types"].invoke

    heading = Macron::Cms::Content.find_by!(name: "heading")
    assert_equal heading_expected_fields, heading.fields

    image = Macron::Cms::Content.find_by!(name: "image")
    assert_equal media_expected_fields, image.fields

    embed = Macron::Cms::Content.find_by!(name: "embed")
    assert_equal media_expected_fields, embed.fields

    markdown = Macron::Cms::Content.find_by!(name: "markdown")
    assert_equal [ { "name" => "content", "kind" => "markdown" } ], markdown.fields

    three_js_quote = Macron::Cms::Content.find_by!(name: "three_js_quote")
    assert_equal [
      { "name" => "text", "kind" => "string" },
      { "name" => "color", "kind" => "color" }
    ], three_js_quote.fields
  end

  test "import task is idempotent and updates existing records" do
    Rake::Task["macron:cms:import_content_types"].invoke
    assert_equal 1, Macron::Cms::Content.where(name: "heading").count

    # Re-enable and re-invoke
    Rake::Task["macron:cms:import_content_types"].reenable
    assert_no_difference -> { Macron::Cms::Content.count } do
      Rake::Task["macron:cms:import_content_types"].invoke
    end

    heading = Macron::Cms::Content.find_by!(name: "heading")
    assert_equal heading_expected_fields, heading.fields
  end

  test "content:import alias runs import_content_types" do
    Rake::Task["macron:cms:content:import"].invoke

    assert Macron::Cms::Content.exists?(name: "heading")
  end

  test "imports legacy hash format fields for backwards compatibility" do
    temp_dir = Dir.mktmpdir("content_types_test")
    legacy_file = File.join(temp_dir, "legacy_card.yml")
    File.write(legacy_file, <<~YAML)
      fields:
        name: 'header'
        kind: 'string'
    YAML

    original_path = Macron::Cms.configuration.content_types_path
    Macron::Cms.configuration.content_types_path = temp_dir

    begin
      Rake::Task["macron:cms:import_content_types"].reenable
      Rake::Task["macron:cms:import_content_types"].invoke

      card = Macron::Cms::Content.find_by!(name: "legacy_card")
      assert_equal({ "name" => "header", "kind" => "string" }, card.fields)
    ensure
      Macron::Cms.configuration.content_types_path = original_path
      FileUtils.remove_entry(temp_dir)
    end
  end
end
