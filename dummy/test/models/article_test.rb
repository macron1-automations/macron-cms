require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  test "requires title" do
    article = Macron::Cms::Article.new
    assert_not article.valid?
    assert_includes article.errors[:title], "can't be blank"

    article.title = "Valid Title"
    assert article.valid?
  end
end
