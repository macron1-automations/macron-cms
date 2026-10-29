require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  test "requires title" do
    article = Macron::Cms::Article.new
    assert_not article.valid?
    assert_includes article.errors[:title], "can't be blank"

    article.title = "Valid Title"
    assert article.valid?
  end

  test "derives slug from title when slug is not provided" do
    article = Macron::Cms::Article.create!(title: "My Brand New Article!")
    assert_equal "my-brand-new-article", article.slug
  end

  test "auto-resolves duplicate derived slugs" do
    first = Macron::Cms::Article.create!(title: "Duplicate Title")
    assert_equal "duplicate-title", first.slug

    second = Macron::Cms::Article.create!(title: "Duplicate Title")
    assert_match(/\Aduplicate-title-/, second.slug)
    assert_not_equal first.slug, second.slug
  end

  test "preserves explicitly provided custom slug" do
    article = Macron::Cms::Article.create!(title: "Some Title", slug: "custom-identifier")
    assert_equal "custom-identifier", article.slug
  end

  test "preserves existing slug on update unless explicitly cleared" do
    article = Macron::Cms::Article.create!(title: "Original Title", slug: "original-slug")
    article.update!(title: "Updated Title")
    assert_equal "original-slug", article.slug

    article.update!(slug: "")
    assert_equal "updated-title", article.slug
  end

  test "auto-resolves duplicate custom slugs" do
    first = Macron::Cms::Article.create!(title: "Article 1", slug: "duplicate-slug")
    second = Macron::Cms::Article.create!(title: "Article 2", slug: "duplicate-slug")

    assert_equal "duplicate-slug", first.slug
    assert_match(/\Aduplicate-slug-/, second.slug)
    assert_not_equal first.slug, second.slug
  end

  test "finds via friendly id" do
    article = Macron::Cms::Article.create!(title: "Getting Started with Rails")
    assert_equal "getting-started-with-rails", article.slug

    found = Macron::Cms::Article.friendly.find("getting-started-with-rails")
    assert_equal article.id, found.id
  end

  test "supports background_color, background_image and background_options" do
    article = Macron::Cms::Article.create!(
      title: "Background Test",
      background_color: "#1e293b",
      background_options: {
        "repeat" => "repeat",
        "size" => "contain",
        "position" => "top",
        "attachment" => "fixed"
      }
    )

    assert_equal "#1e293b", article.background_color
    assert_equal "repeat", article.background_repeat
    assert_equal "contain", article.background_size
    assert_equal "top", article.background_position
    assert_equal "fixed", article.background_attachment

    # Attach background image
    file = Rack::Test::UploadedFile.new(StringIO.new("fake image data"), "image/png", original_filename: "bg.png")
    article.background_image.attach(file)
    assert article.background_image.attached?
    assert_equal "bg.png", article.background_image.filename.to_s
  end

  test "background option getters fall back to default values when unset or invalid" do
    article = Macron::Cms::Article.new(title: "Defaults Test", background_options: {})

    assert_equal "no-repeat", article.background_repeat
    assert_equal "cover", article.background_size
    assert_equal "center", article.background_position
    assert_equal "scroll", article.background_attachment

    article.background_options = { "repeat" => "invalid", "size" => "unknown", "position" => "nowhere", "attachment" => "float" }
    assert_equal "no-repeat", article.background_repeat
    assert_equal "cover", article.background_size
    assert_equal "center", article.background_position
    assert_equal "scroll", article.background_attachment
  end

  test "supports text_color" do
    article = Macron::Cms::Article.create!(title: "Text Color Test", text_color: "#f8fafc")
    assert_equal "#f8fafc", article.text_color
  end

  test "featured_image delegates to featured_image_blob" do
    article = Macron::Cms::Article.create!(title: "Featured Image Test")
    assert_nil article.featured_image
    assert_nil article.featured_image_blob

    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("fake image data"),
      filename: "test.png",
      content_type: "image/png"
    )
    article.update!(featured_image_blob: blob)

    assert_equal blob, article.reload.featured_image
    assert_equal blob, article.featured_image_blob
  end

  test "slug update records history in friendly_id_slugs" do
    article = Macron::Cms::Article.create!(title: "Independent Test", slug: "initial-slug")
    article.update!(slug: "updated-slug")

    assert_equal "updated-slug", article.slug
    assert article.slugs.where(slug: "initial-slug").exists?
  end

  test "slug is automatically parameterized on assignment" do
    article = Macron::Cms::Article.create!(title: "Formatting Test", slug: "Custom Slug With Spaces & Special #1!")
    assert_equal "custom-slug-with-spaces-special-1", article.slug
  end

  test "clearing slug re-derives slug from title" do
    article = Macron::Cms::Article.create!(title: "Auto Regeneration Test", slug: "custom-temporary-slug")
    article.update!(slug: "")

    assert_equal "auto-regeneration-test", article.slug
  end
end
