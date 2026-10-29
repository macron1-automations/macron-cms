require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  test "loading engine seeds populates seo metadata for all articles" do
    Macron::Cms::Article.delete_all

    Macron::Cms::Engine.load_seed

    assert_equal 10, Macron::Cms::Article.count
    Macron::Cms::Article.find_each do |article|
      assert_predicate article.title, :present?, "Article #{article.slug} is missing title"
      assert_predicate article.meta_title, :present?, "Article #{article.slug} is missing meta_title"
      assert_predicate article.meta_description, :present?, "Article #{article.slug} is missing meta_description"
    end
  end

  test "re-running seeds updates existing articles idempotently" do
    Macron::Cms::Article.delete_all

    Macron::Cms::Engine.load_seed
    first_count = Macron::Cms::Article.count

    # Run again without clearing
    assert_no_difference("Macron::Cms::Article.count") do
      Macron::Cms::Engine.load_seed
    end

    assert_equal first_count, Macron::Cms::Article.count
  end
end
