require "test_helper"

class ArticleContentTest < ActiveSupport::TestCase
  test "article has many contents through article_contents ordered by sort_order" do
    article = Macron::Cms::Article.create!(title: "Main Article")
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
    article = Macron::Cms::Article.create!(title: "Sequential Article")
    content = Macron::Cms::Content.create!(name: "heading-test", fields: [ { "name" => "title", "kind" => "string" } ])

    block1 = Macron::Cms::ArticleContent.create!(article: article, content: content)
    block2 = Macron::Cms::ArticleContent.create!(article: article, content: content)
    block3 = Macron::Cms::ArticleContent.create!(article: article, content: content)

    assert_equal 1, block1.sort_order
    assert_equal 2, block2.sort_order
    assert_equal 3, block3.sort_order
  end

  test "allows multiple content blocks of the same content type with different payloads" do
    article = Macron::Cms::Article.create!(title: "Multi Heading Article")
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
    article = Macron::Cms::Article.create!(title: "To Delete")
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

  test "has_many_attached :files with convenience methods upload, file, and uploads" do
    article = Macron::Cms::Article.create!(title: "Attach Article")
    content = Macron::Cms::Content.create!(name: "image-test", fields: [ { "name" => "upload", "kind" => "file" } ])
    article_content = Macron::Cms::ArticleContent.create!(article: article, content: content)

    assert_not article_content.files.attached?
    assert_nil article_content.upload
    assert_nil article_content.file

    file1 = Rack::Test::UploadedFile.new(StringIO.new("fake image data"), "image/png", original_filename: "image1.png")
    article_content.files.attach(file1)

    assert article_content.files.attached?
    assert_equal 1, article_content.files.count
    assert_equal "image1.png", article_content.upload.filename.to_s
    assert_equal "image1.png", article_content.file.filename.to_s
    assert_equal article_content.files, article_content.uploads

    # Test attach_upload with replace: true
    file2 = Rack::Test::UploadedFile.new(StringIO.new("replacement data"), "image/png", original_filename: "image2.png")
    article_content.attach_upload(file2, replace: true)

    assert_equal 1, article_content.files.count
    assert_equal "image2.png", article_content.upload.filename.to_s
  end

  test "filter_payload serializes UploadedFile to its original_filename" do
    content = Macron::Cms::Content.create!(
      name: "file-content",
      fields: [ { "name" => "upload", "kind" => "file" } ]
    )
    article_content = Macron::Cms::ArticleContent.new(content: content)
    uploaded = Rack::Test::UploadedFile.new(StringIO.new("content"), "text/html", original_filename: "widget.html")

    filtered = article_content.filter_payload({ "upload" => uploaded })
    assert_equal({ "upload" => "widget.html" }, filtered)
  end

  test "convert_to converts block in place preserving attached files, sort_order, and all payload keys across round-trip" do
    article = Macron::Cms::Article.create!(title: "Convert Article")
    image_type = Macron::Cms::Content.create!(
      name: "image",
      fields: [ { "name" => "upload", "kind" => "file" }, { "name" => "size", "kind" => "dropdown" } ],
      convertible_to: [ "three_js_image" ]
    )
    three_js_type = Macron::Cms::Content.create!(
      name: "three_js_image",
      fields: [
        { "name" => "upload", "kind" => "file" },
        { "name" => "size", "kind" => "dropdown" },
        { "name" => "effect", "kind" => "dropdown" }
      ],
      convertible_to: [ "image" ]
    )

    block = Macron::Cms::ArticleContent.create!(
      article: article,
      content: image_type,
      sort_order: 2,
      payload: { "upload" => "hero.png", "size" => "lg" }
    )
    uploaded = Rack::Test::UploadedFile.new(StringIO.new("png-bytes"), "image/png", original_filename: "hero.png")
    block.files.attach(uploaded)
    original_blob_id = block.upload.blob_id

    assert block.convert_to(three_js_type)
    block.reload
    assert_equal three_js_type, block.content
    assert_equal 2, block.sort_order
    assert block.files.attached?
    assert_equal original_blob_id, block.upload.blob_id
    assert_equal({ "upload" => "hero.png", "size" => "lg" }, block.payload)

    # Set a three_js_image-specific field, convert back to image, then back to three_js_image
    block.update!(payload: block.payload.merge("effect" => "glitch"))
    assert block.convert_to(image_type)
    block.reload
    assert_equal image_type, block.content
    assert_equal original_blob_id, block.upload.blob_id
    assert_equal "glitch", block.payload["effect"]
    assert_equal "lg", block.payload["size"]

    assert block.convert_to(three_js_type)
    block.reload
    assert_equal three_js_type, block.content
    assert_equal "glitch", block.payload["effect"]
    assert_equal original_blob_id, block.upload.blob_id
  end

  test "convert_to rejects non-convertible target content type" do
    article = Macron::Cms::Article.create!(title: "Reject Convert")
    image_type = Macron::Cms::Content.create!(name: "image", fields: [], convertible_to: [ "three_js_image" ])
    heading_type = Macron::Cms::Content.create!(name: "heading", fields: [])

    block = Macron::Cms::ArticleContent.create!(article: article, content: image_type)

    assert_not block.convert_to(heading_type)
    assert_includes block.errors[:base].join, "Cannot convert image block to heading"
    assert_equal image_type, block.reload.content
  end

  test "saving article_content with featured_image content type bubbles up first attached image to article" do
    article = Macron::Cms::Article.create!(title: "Bubbling Article")
    image_type = Macron::Cms::Content.create!(
      name: "image",
      fields: [ { "name" => "upload", "kind" => "file" } ],
      featured_image: true
    )
    non_featured_type = Macron::Cms::Content.create!(
      name: "embed",
      fields: [ { "name" => "upload", "kind" => "file" } ],
      featured_image: false
    )

    # 1. Non-featured block with attached file does NOT become article.featured_image
    non_featured_block = Macron::Cms::ArticleContent.create!(article: article, content: non_featured_type, sort_order: 1)
    file_html = Rack::Test::UploadedFile.new(StringIO.new("html"), "text/html", original_filename: "doc.html")
    non_featured_block.files.attach(file_html)
    assert_nil article.reload.featured_image_blob_id

    # 2. Featured image block with attached file bubbles up
    block1 = Macron::Cms::ArticleContent.create!(article: article, content: image_type, sort_order: 2)
    file1 = Rack::Test::UploadedFile.new(StringIO.new("img1"), "image/png", original_filename: "img1.png")
    block1.files.attach(file1)
    assert_equal block1.upload.blob_id, article.reload.featured_image_blob_id

    # 3. Second featured image block added later with higher sort_order does not override first
    block2 = Macron::Cms::ArticleContent.create!(article: article, content: image_type, sort_order: 3)
    file2 = Rack::Test::UploadedFile.new(StringIO.new("img2"), "image/png", original_filename: "img2.png")
    block2.files.attach(file2)
    assert_equal block1.upload.blob_id, article.reload.featured_image_blob_id

    # 4. Destroying the first block updates article.featured_image to the second block
    block1.destroy!
    assert_equal block2.upload.blob_id, article.reload.featured_image_blob_id

    # 5. Destroying the remaining block clears article.featured_image
    block2.destroy!
    assert_nil article.reload.featured_image_blob_id
  end

  test "for_display eager loads content, files_attachments, and blobs without N+1 queries" do
    article = Macron::Cms::Article.create!(title: "Display Scope Test")
    image_type = Macron::Cms::Content.create!(
      name: "scope_image",
      fields: [ { "name" => "upload", "kind" => "file" } ]
    )

    3.times do |i|
      ac = Macron::Cms::ArticleContent.create!(article: article, content: image_type, sort_order: i + 1)
      ac.files.attach(Rack::Test::UploadedFile.new(StringIO.new("data#{i}"), "image/png", original_filename: "img#{i}.png"))
    end

    blocks = article.article_contents.for_display.to_a
    assert_equal 3, blocks.size

    queries = count_queries do
      blocks.each do |b|
        assert_equal "scope_image", b.content.name
        assert b.files.attached?
        assert_not_nil b.files.first.blob.filename
      end
    end

    assert_equal 0, queries, "Expected zero database queries when accessing preloaded content and attachments"
  end
end
