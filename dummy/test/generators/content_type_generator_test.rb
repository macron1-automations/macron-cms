# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/macron/cms/content_type/content_type_generator"

class ContentTypeGeneratorTest < Rails::Generators::TestCase
  tests Macron::Cms::Generators::ContentTypeGenerator
  destination Rails.root.join("tmp/generators")

  setup do
    @temp_destination = Dir.mktmpdir("generator_test", Rails.root.join("tmp"))
    self.destination_root = @temp_destination
  end

  teardown do
    FileUtils.remove_entry(@temp_destination) if @temp_destination && File.exist?(@temp_destination)
  end

  test "generates content type with a single field in array format" do
    run_generator %w[article title:string]

    assert_file "config/content_types/article.yml" do |content|
      expected = <<~YAML
        fields:
          - name: 'title'
            kind: 'string'
      YAML
      assert_equal expected, content
    end
  end

  test "generates content type with multiple fields in array format" do
    run_generator %w[banner title:string subtitle:text count:integer]

    assert_file "config/content_types/banner.yml" do |content|
      expected = <<~YAML
        fields:
          - name: 'title'
            kind: 'string'
          - name: 'subtitle'
            kind: 'text'
          - name: 'count'
            kind: 'integer'
      YAML
      assert_equal expected, content
    end
  end

  test "generates content type with no fields as empty array" do
    run_generator %w[footer]

    assert_file "config/content_types/footer.yml" do |content|
      assert_equal "fields: []\n", content
    end
  end

  test "displays error and aborts when field is missing kind delimiter" do
    output = capture(:stderr) do
      run_generator %w[hero bad_field]
    end

    assert_match(/Invalid field 'bad_field'/, output)
    assert_match(/name:kind/, output)
    assert_no_file "config/content_types/hero.yml"
  end

  test "displays error and aborts when field has empty name or kind" do
    output = capture(:stderr) do
      run_generator %w[hero :string]
    end
    assert_match(/Invalid field ':string'/, output)
    assert_no_file "config/content_types/hero.yml"

    output = capture(:stderr) do
      run_generator %w[hero title:]
    end
    assert_match(/Invalid field 'title:'/, output)
    assert_no_file "config/content_types/hero.yml"
  end

  test "underscores camelcase or dasherized content type name" do
    run_generator %w[BlogPost title:string]

    assert_file "config/content_types/blog_post.yml"
  end

  test "respects configured content_types_path" do
    original_path = Macron::Cms.configuration.content_types_path
    Macron::Cms.configuration.content_types_path = "custom/content_types"

    begin
      run_generator %w[custom_card title:string]
      assert_file "custom/content_types/custom_card.yml"
    ensure
      Macron::Cms.configuration.content_types_path = original_path
    end
  end

  test "generated YAML file is compatible with import task" do
    run_generator %w[testimonial author:string quote:text]
    file_path = File.join(destination_root, "config/content_types/testimonial.yml")

    data = YAML.safe_load_file(file_path)
    assert_equal [
      { "name" => "author", "kind" => "string" },
      { "name" => "quote", "kind" => "text" }
    ], data["fields"]
  end
end
