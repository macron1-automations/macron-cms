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
    assert_equal({ "name" => "title", "kind" => "string" }, heading.fields)
    assert_equal({}, heading.payload)
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
    assert_equal({ "name" => "title", "kind" => "string" }, heading.fields)
  end

  test "content:import alias runs import_content_types" do
    Rake::Task["macron:cms:content:import"].invoke

    assert Macron::Cms::Content.exists?(name: "heading")
  end
end
