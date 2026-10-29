require "test_helper"

class ContentTest < ActiveSupport::TestCase
  test "requires name" do
    content = Macron::Cms::Content.new(fields: {})
    assert_not content.valid?
    assert_includes content.errors[:name], "can't be blank"
  end

  test "enforces unique name" do
    Macron::Cms::Content.create!(name: "heading", fields: { "name" => "title" })
    duplicate = Macron::Cms::Content.new(name: "heading")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "stores fields as json" do
    content = Macron::Cms::Content.create!(
      name: "custom_block",
      fields: [ { "name" => "headline", "kind" => "string" }, { "name" => "body", "kind" => "text" } ]
    )

    content.reload
    assert_equal 2, content.fields.size
    assert_equal "headline", content.fields.first["name"]
  end

  test "normalized_fields handles array of fields" do
    content = Macron::Cms::Content.new(
      name: "hero",
      fields: [
        { "name" => "title", "kind" => "string" },
        { "name" => "subtitle", "kind" => "text" }
      ]
    )

    assert_equal [
      { "name" => "title", "kind" => "string" },
      { "name" => "subtitle", "kind" => "text" }
    ], content.normalized_fields
    assert_equal [ "title", "subtitle" ], content.field_names
  end

  test "normalized_fields handles legacy hash fields" do
    content = Macron::Cms::Content.new(
      name: "legacy",
      fields: { "name" => "title", "kind" => "string" }
    )

    assert_equal [
      { "name" => "title", "kind" => "string" }
    ], content.normalized_fields
    assert_equal [ "title" ], content.field_names
  end

  test "normalized_convertible_to normalizes, deduplicates, and excludes self" do
    content = Macron::Cms::Content.new(
      name: "image",
      convertible_to: [ " three_js_image ", "", nil, "three_js_image", "image", :embed ]
    )

    assert_equal [ "three_js_image", "embed" ], content.normalized_convertible_to
    assert content.convertible_to?("three_js_image")
    assert content.convertible_to?(:embed)
    assert_not content.convertible_to?("image")
    assert_not content.convertible_to?("heading")
  end

  test "convertible_targets resolves matching Content records in declared order" do
    three_js = Macron::Cms::Content.create!(name: "three_js_image", fields: [])
    embed = Macron::Cms::Content.create!(name: "embed", fields: [])
    image = Macron::Cms::Content.create!(
      name: "image",
      fields: [],
      convertible_to: [ "embed", "missing_type", "three_js_image" ]
    )

    assert_equal [ embed, three_js ], image.convertible_targets
    assert_equal [ embed, three_js ], image.convertible_targets([ three_js, embed, image ])
    assert image.convertible_to?(three_js)
  end
end
