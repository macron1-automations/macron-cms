require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  test "requires title" do
    article = Macron::Cms::Article.new(name: "unique-title-test")
    assert_not article.valid?
    assert_includes article.errors[:title], "can't be blank"

    article.title = "Valid Title"
    assert article.valid?
  end

  test "requires name" do
    article = Macron::Cms::Article.new(title: "Valid Title")
    assert_not article.valid?
    assert_includes article.errors[:name], "can't be blank"
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
end
