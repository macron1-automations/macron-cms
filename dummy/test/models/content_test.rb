require "test_helper"

class ContentTest < ActiveSupport::TestCase
  test "requires name" do
    content = Macron::Cms::Content.new(fields: {}, payload: {})
    assert_not content.valid?
    assert_includes content.errors[:name], "can't be blank"
  end

  test "enforces unique name" do
    Macron::Cms::Content.create!(name: "heading", fields: { "name" => "title" }, payload: {})
    duplicate = Macron::Cms::Content.new(name: "heading")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "stores fields and payload as json" do
    content = Macron::Cms::Content.create!(
      name: "custom_block",
      fields: { "kind" => "hero", "color" => "blue" },
      payload: { "headline" => "Welcome", "cta_url" => "/start" }
    )

    content.reload
    assert_equal "hero", content.fields["kind"]
    assert_equal "Welcome", content.payload["headline"]
  end
end
