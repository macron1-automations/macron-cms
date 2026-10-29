require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  test "requires title" do
    article = Macron::Cms::Article.new(name: "unique-title-test")
    assert_not article.valid?
    assert_includes article.errors[:title], "can't be blank"

    article.title = "Valid Title"
    assert article.valid?
  end

  test "derives name from title when name is not provided" do
    article = Macron::Cms::Article.create!(title: "My Brand New Article!")
    assert_equal "my-brand-new-article", article.name
    assert_equal "my-brand-new-article", article.slug
  end

  test "auto-resolves duplicate derived names with numeric suffix" do
    first = Macron::Cms::Article.create!(title: "Duplicate Title")
    assert_equal "duplicate-title", first.name

    second = Macron::Cms::Article.create!(title: "Duplicate Title")
    assert_equal "duplicate-title-2", second.name

    third = Macron::Cms::Article.create!(title: "Duplicate Title")
    assert_equal "duplicate-title-3", third.name
  end

  test "preserves explicitly provided custom name" do
    article = Macron::Cms::Article.create!(title: "Some Title", name: "custom-identifier")
    assert_equal "custom-identifier", article.name
  end

  test "preserves existing name on update unless explicitly cleared" do
    article = Macron::Cms::Article.create!(title: "Original Title", name: "original-name")
    article.update!(title: "Updated Title")
    assert_equal "original-name", article.name

    article.update!(name: "")
    assert_equal "updated-title", article.name
  end

  test "requires title when name is also blank" do
    article = Macron::Cms::Article.new
    assert_not article.valid?
    assert_includes article.errors[:title], "can't be blank"
  end

  test "enforces unique name" do
    Macron::Cms::Article.create!(title: "Article 1", name: "duplicate-name")
    duplicate = Macron::Cms::Article.new(title: "Article 2", name: "duplicate-name")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "generates slug from name and finds via friendly id" do
    article = Macron::Cms::Article.create!(title: "Getting Started with Rails", name: "getting-started-rails")
    assert_equal "getting-started-rails", article.slug

    found = Macron::Cms::Article.friendly.find("getting-started-rails")
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
end
