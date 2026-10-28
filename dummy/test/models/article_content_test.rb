require "test_helper"

class ArticleContentTest < ActiveSupport::TestCase
  test "article has many contents through article_contents ordered by sort_order" do
    article = Macron::Cms::Article.create!(title: "Main Article", name: "main-article-contents-test")
    content_a = Macron::Cms::Content.create!(name: "content-a", fields: {}, payload: { "text" => "First" })
    content_b = Macron::Cms::Content.create!(name: "content-b", fields: {}, payload: { "text" => "Second" })
    content_c = Macron::Cms::Content.create!(name: "content-c", fields: {}, payload: { "text" => "Third" })

    # Associate in non-sequential order
    Macron::Cms::ArticleContent.create!(article: article, content: content_b, sort_order: 2)
    Macron::Cms::ArticleContent.create!(article: article, content: content_a, sort_order: 1)
    Macron::Cms::ArticleContent.create!(article: article, content: content_c, sort_order: 3)

    assert_equal [ content_a, content_b, content_c ], article.reload.contents
    assert_equal [ 1, 2, 3 ], article.article_contents.pluck(:sort_order)
  end

  test "destroying article removes article_contents but keeps contents" do
    article = Macron::Cms::Article.create!(title: "To Delete", name: "to-delete-article")
    content = Macron::Cms::Content.create!(name: "shared-content", fields: {}, payload: {})
    join = Macron::Cms::ArticleContent.create!(article: article, content: content, sort_order: 1)

    assert_difference -> { Macron::Cms::ArticleContent.count }, -1 do
      assert_no_difference -> { Macron::Cms::Content.count } do
        article.destroy!
      end
    end

    assert_not Macron::Cms::ArticleContent.exists?(join.id)
    assert Macron::Cms::Content.exists?(content.id)
  end
end
