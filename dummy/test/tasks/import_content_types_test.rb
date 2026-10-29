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

  def embed_expected_fields
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
      },
      {
        "name" => "height",
        "kind" => "dropdown",
        "options" => [
          { "name" => "Large (480px)", "value" => "lg" },
          { "name" => "Extra Large (640px)", "value" => "xl" },
          { "name" => "Very Large (800px)", "value" => "2xl" }
        ]
      }
    ]
  end

  def three_js_image_expected_fields
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
      },
      {
        "name" => "effect",
        "kind" => "dropdown",
        "options" => [
          { "name" => "Water Ripple", "value" => "ripple" },
          { "name" => "Underwater Wave", "value" => "wave" },
          { "name" => "RGB Glitch", "value" => "glitch" }
        ]
      },
      {
        "name" => "animation_speed",
        "kind" => "dropdown",
        "options" => [
          { "name" => "Slow", "value" => "slow" },
          { "name" => "Normal", "value" => "normal" },
          { "name" => "Fast", "value" => "fast" }
        ]
      },
      {
        "name" => "intensity",
        "kind" => "dropdown",
        "options" => [
          { "name" => "Subtle", "value" => "subtle" },
          { "name" => "Medium", "value" => "medium" },
          { "name" => "Strong", "value" => "strong" }
        ]
      },
      {
        "name" => "canvas_height",
        "kind" => "dropdown",
        "options" => [
          { "name" => "Small (240px)", "value" => "sm" },
          { "name" => "Medium (320px)", "value" => "md" },
          { "name" => "Large (480px)", "value" => "lg" },
          { "name" => "Extra Large (640px)", "value" => "xl" }
        ]
      },
      {
        "name" => "fit_mode",
        "kind" => "dropdown",
        "options" => [
          { "name" => "Cover (Fill & Crop)", "value" => "cover" },
          { "name" => "Contain (Fit Inside)", "value" => "contain" }
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

    three_js_image = Macron::Cms::Content.find_by!(name: "three_js_image")
    assert_equal three_js_image_expected_fields, three_js_image.fields

    embed = Macron::Cms::Content.find_by!(name: "embed")
    assert_equal embed_expected_fields, embed.fields

    markdown = Macron::Cms::Content.find_by!(name: "markdown")
    assert_equal [ { "name" => "content", "kind" => "markdown" } ], markdown.fields

    three_js_quote = Macron::Cms::Content.find_by!(name: "three_js_quote")
    assert_equal [
      { "name" => "text", "kind" => "string" },
      { "name" => "color", "kind" => "color" },
      {
        "name" => "rotation_axis",
        "kind" => "dropdown",
        "options" => [
          { "name" => "X Axis", "value" => "x" },
          { "name" => "Y Axis", "value" => "y" },
          { "name" => "Z Axis", "value" => "z" }
        ]
      },
      {
        "name" => "rotation_speed",
        "kind" => "dropdown",
        "options" => [
          { "name" => "0x (Paused)", "value" => "0" },
          { "name" => "0.5x", "value" => "0.5" },
          { "name" => "1x", "value" => "1" },
          { "name" => "1.5x", "value" => "1.5" },
          { "name" => "2x", "value" => "2" },
          { "name" => "3x", "value" => "3" }
        ]
      },
      {
        "name" => "canvas_height",
        "kind" => "dropdown",
        "options" => [
          { "name" => "Small (240px)", "value" => "sm" },
          { "name" => "Medium (320px)", "value" => "md" },
          { "name" => "Large (480px)", "value" => "lg" },
          { "name" => "Extra Large (640px)", "value" => "xl" }
        ]
      },
      {
        "name" => "font_size",
        "kind" => "dropdown",
        "options" => [
          { "name" => "Small", "value" => "sm" },
          { "name" => "Medium", "value" => "md" },
          { "name" => "Large", "value" => "lg" },
          { "name" => "Extra Large", "value" => "xl" }
        ]
      },
      {
        "name" => "font",
        "kind" => "dropdown",
        "options" => [
          { "name" => "Helvetiker (Sans-serif)", "value" => "helvetiker" },
          { "name" => "Optimer (Modern Sans)", "value" => "optimer" },
          { "name" => "Gentilis (Humanist Sans)", "value" => "gentilis" },
          { "name" => "Droid Serif (Serif)", "value" => "droid_serif" }
        ]
      },
      { "name" => "background_color", "kind" => "color" },
      { "name" => "upload", "kind" => "file" },
      {
        "name" => "background_mode",
        "kind" => "dropdown",
        "options" => [
          { "name" => "Stretch", "value" => "stretch" },
          { "name" => "Tile", "value" => "tile" }
        ]
      },
      {
        "name" => "scanlines_intensity",
        "kind" => "dropdown",
        "options" => [
          { "name" => "Off", "value" => "off" },
          { "name" => "Subtle", "value" => "subtle" },
          { "name" => "Medium", "value" => "medium" },
          { "name" => "Strong", "value" => "strong" }
        ]
      },
      {
        "name" => "scanlines_density",
        "kind" => "dropdown",
        "options" => [
          { "name" => "Fine", "value" => "fine" },
          { "name" => "Medium", "value" => "medium" },
          { "name" => "Coarse", "value" => "coarse" }
        ]
      },
      {
        "name" => "scanlines_speed",
        "kind" => "dropdown",
        "options" => [
          { "name" => "Still", "value" => "still" },
          { "name" => "Slow", "value" => "slow" },
          { "name" => "Normal", "value" => "normal" },
          { "name" => "Fast", "value" => "fast" }
        ]
      }
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
