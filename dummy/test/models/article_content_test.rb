require "test_helper"

class ArticleContentTest < ActiveSupport::TestCase
  test "article has many contents through article_contents ordered by sort_order" do
    article = Macron::Cms::Article.create!(title: "Main Article", name: "main-article-contents-test")
    content_a = Macron::Cms::Content.create!(name: "content-a", fields: [])
    content_b = Macron::Cms::Content.create!(name: "content-b", fields: [])
    content_c = Macron::Cms::Content.create!(name: "content-c", fields: [])

    # Associate in non-sequential order
    Macron::Cms::ArticleContent.create!(article: article, content: content_b, sort_order: 2, payload: { "text" => "Second" })
    Macron::Cms::ArticleContent.create!(article: article, content: content_a, sort_order: 1, payload: { "text" => "First" })
    Macron::Cms::ArticleContent.create!(article: article, content: content_c, sort_order: 3, payload: { "text" => "Third" })

    assert_equal [ content_a, content_b, content_c ], article.reload.contents
    assert_equal [ 1, 2, 3 ], article.article_contents.pluck(:sort_order)
  end

  test "auto assigns sort_order sequentially on creation if omitted" do
    article = Macron::Cms::Article.create!(title: "Sequential Article", name: "seq-article")
    content = Macron::Cms::Content.create!(name: "heading-test", fields: [ { "name" => "title", "kind" => "string" } ])

    block1 = Macron::Cms::ArticleContent.create!(article: article, content: content)
    block2 = Macron::Cms::ArticleContent.create!(article: article, content: content)
    block3 = Macron::Cms::ArticleContent.create!(article: article, content: content)

    assert_equal 1, block1.sort_order
    assert_equal 2, block2.sort_order
    assert_equal 3, block3.sort_order
  end

  test "allows multiple content blocks of the same content type with different payloads" do
    article = Macron::Cms::Article.create!(title: "Multi Heading Article", name: "multi-heading")
    heading_type = Macron::Cms::Content.create!(
      name: "heading",
      fields: [
        { "name" => "title", "kind" => "string" },
        { "name" => "level", "kind" => "string" }
      ]
    )

    block1 = Macron::Cms::ArticleContent.create!(
      article: article,
      content: heading_type,
      payload: { "title" => "First Heading", "level" => "h1" }
    )
    block2 = Macron::Cms::ArticleContent.create!(
      article: article,
      content: heading_type,
      payload: { "title" => "Second Heading", "level" => "h2" }
    )

    assert_equal 2, article.article_contents.count
    assert_equal "First Heading", block1.reload.payload["title"]
    assert_equal "Second Heading", block2.reload.payload["title"]
  end

  test "filter_payload only permits keys defined in content fields" do
    content = Macron::Cms::Content.create!(
      name: "card",
      fields: [
        { "name" => "title", "kind" => "string" },
        { "name" => "description", "kind" => "text" }
      ]
    )
    article_content = Macron::Cms::ArticleContent.new(content: content)

    filtered = article_content.filter_payload({
      "title" => "Card Title",
      "description" => "A long description",
      "malicious_key" => "injected",
      "another_extra" => 123
    })

    assert_equal({ "title" => "Card Title", "description" => "A long description" }, filtered)
  end

  test "destroying article removes article_contents but keeps contents" do
    article = Macron::Cms::Article.create!(title: "To Delete", name: "to-delete-article")
    content = Macron::Cms::Content.create!(name: "shared-content", fields: [])
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
