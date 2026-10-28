require "test_helper"
require "rake"

class ImportContentTypesTaskTest < ActiveSupport::TestCase
  setup do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rails.application.load_tasks
  end

  test "imports heading content type from yml" do
    Rake::Task["macron:cms:import_content_types"].invoke

    heading = Macron::Cms::Content.find_by!(name: "heading")
    expected_fields = [
      { "name" => "title", "kind" => "string" },
      { "name" => "level", "kind" => "string" }
    ]
    assert_equal expected_fields, heading.fields
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
    expected_fields = [
      { "name" => "title", "kind" => "string" },
      { "name" => "level", "kind" => "string" }
    ]
    assert_equal expected_fields, heading.fields
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
