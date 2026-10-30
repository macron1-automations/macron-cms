require "test_helper"

class ContentBlocksApiTest < ActionDispatch::IntegrationTest
  setup do
    @original_key = Macron::Cms.configuration.api_key
    Macron::Cms.configuration.api_key = "test-secret-key"
    @auth_headers = {
      "Authorization" => "Bearer test-secret-key",
      "Content-Type" => "application/json"
    }

    @heading_type = Macron::Cms::Content.find_or_create_by!(name: "heading") do |c|
      c.fields = [
        { "name" => "title", "kind" => "string" },
        { "name" => "level", "kind" => "dropdown" }
      ]
    end

    @markdown_type = Macron::Cms::Content.find_or_create_by!(name: "markdown") do |c|
      c.fields = [ { "name" => "content", "kind" => "markdown" } ]
    end

    @image_type = Macron::Cms::Content.find_or_initialize_by(name: "image")
    @image_type.fields = [
      { "name" => "upload", "kind" => "file" },
      { "name" => "size", "kind" => "dropdown" }
    ]
    @image_type.convertible_to = [ "three_js_image" ]
    @image_type.featured_image = true
    @image_type.save!

    @three_js_type = Macron::Cms::Content.find_or_initialize_by(name: "three_js_image")
    @three_js_type.fields = [
      { "name" => "upload", "kind" => "file" },
      { "name" => "effect", "kind" => "dropdown" }
    ]
    @three_js_type.convertible_to = [ "image" ]
    @three_js_type.featured_image = true
    @three_js_type.save!

    @article = Macron::Cms::Article.create!(title: "Block Operations Test Article")
  end

  teardown do
    Macron::Cms.configuration.api_key = @original_key
  end

  test "POST /cms/api/v1/articles/:article_id/content_blocks appends block" do
    payload = {
      content_type: "heading",
      payload: { title: "Appended Heading", level: "h2" }
    }

    post "/cms/api/v1/articles/#{@article.slug}/content_blocks", params: payload.to_json, headers: @auth_headers
    assert_response :created

    json = JSON.parse(response.body)
    assert_equal "heading", json["content_block"]["content_type"]
    assert_equal "Appended Heading", json["content_block"]["payload"]["title"]
    assert_equal 1, json["content_block"]["sort_order"]
    assert_equal 1, json["blocks_count"]
  end

  test "POST /cms/api/v1/articles/:article_id/content_blocks with insert_at shifts existing blocks" do
    b1 = @article.article_contents.create!(content: @heading_type, sort_order: 1, payload: { "title" => "First" })
    b2 = @article.article_contents.create!(content: @markdown_type, sort_order: 2, payload: { "content" => "Second" })

    payload = {
      content_type: "heading",
      insert_at: 2,
      payload: { title: "Inserted Between" }
    }

    post "/cms/api/v1/articles/#{@article.slug}/content_blocks", params: payload.to_json, headers: @auth_headers
    assert_response :created

    json = JSON.parse(response.body)
    assert_equal 2, json["content_block"]["sort_order"]
    assert_equal 3, json["blocks_count"]

    b1.reload
    b2.reload
    assert_equal 1, b1.sort_order
    assert_equal 3, b2.sort_order
  end

  test "POST /cms/api/v1/articles/:article_id/content_blocks supports inline base64 file upload" do
    png_base64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
    payload = {
      content_type: "image",
      payload: { size: "lg" },
      file_upload: {
        filename: "tiny.png",
        content_type: "image/png",
        data_base64: png_base64
      }
    }

    post "/cms/api/v1/articles/#{@article.slug}/content_blocks", params: payload.to_json, headers: @auth_headers
    assert_response :created

    json = JSON.parse(response.body)
    assert_not_nil json["content_block"]["attached_file"]
    assert_equal "tiny.png", json["content_block"]["attached_file"]["filename"]
    assert_equal "image/png", json["content_block"]["attached_file"]["content_type"]

    @article.reload
    assert_not_nil @article.featured_image
  end

  test "PATCH /cms/api/v1/articles/:article_id/content_blocks/:id updates block payload and attachment" do
    block = @article.article_contents.create!(
      content: @heading_type,
      sort_order: 1,
      payload: { "title" => "Original Title", "level" => "h1" }
    )

    patch "/cms/api/v1/articles/#{@article.slug}/content_blocks/#{block.id}",
          params: { payload: { title: "Updated Title" } }.to_json,
          headers: @auth_headers
    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal "Updated Title", json["content_block"]["payload"]["title"]
    # Existing key preserved by default
    assert_equal "h1", json["content_block"]["payload"]["level"]
  end

  test "DELETE /cms/api/v1/articles/:article_id/content_blocks/:id removes block and re-normalizes order" do
    b1 = @article.article_contents.create!(content: @heading_type, sort_order: 1, payload: { "title" => "Block 1" })
    b2 = @article.article_contents.create!(content: @heading_type, sort_order: 2, payload: { "title" => "Block 2" })
    b3 = @article.article_contents.create!(content: @heading_type, sort_order: 3, payload: { "title" => "Block 3" })

    delete "/cms/api/v1/articles/#{@article.slug}/content_blocks/#{b2.id}", headers: @auth_headers
    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal true, json["deleted"]
    assert_equal b2.id, json["id"]

    assert_equal [ 1, 2 ], @article.article_contents.reload.pluck(:sort_order)
    assert_equal [ b1.id, b3.id ], @article.article_contents.pluck(:id)
  end

  test "PATCH /cms/api/v1/articles/:article_id/content_blocks/reorder reorders blocks" do
    b1 = @article.article_contents.create!(content: @heading_type, sort_order: 1, payload: { "title" => "A" })
    b2 = @article.article_contents.create!(content: @heading_type, sort_order: 2, payload: { "title" => "B" })
    b3 = @article.article_contents.create!(content: @heading_type, sort_order: 3, payload: { "title" => "C" })

    patch "/cms/api/v1/articles/#{@article.slug}/content_blocks/reorder",
          params: { ordered_ids: [ b3.id, b1.id, b2.id ] }.to_json,
          headers: @auth_headers
    assert_response :ok

    json = JSON.parse(response.body)
    new_order_ids = json["content_blocks"].map { |b| b["id"] }
    assert_equal [ b3.id, b1.id, b2.id ], new_order_ids
  end

  test "PATCH /cms/api/v1/articles/:article_id/content_blocks/:id/convert converts block type in-place" do
    png_base64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
    block = @article.article_contents.create!(
      content: @image_type,
      sort_order: 1,
      payload: { "size" => "lg" }
    )
    Macron::Cms::InlineAssetAttacher.attach(
      article_content: block,
      upload_data: { filename: "test.png", content_type: "image/png", data_base64: png_base64 }
    )

    patch "/cms/api/v1/articles/#{@article.slug}/content_blocks/#{block.id}/convert",
          params: { target_content_type: "three_js_image" }.to_json,
          headers: @auth_headers
    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal "three_js_image", json["content_block"]["content_type"]
    assert_not_nil json["content_block"]["attached_file"]
    assert_equal "test.png", json["content_block"]["attached_file"]["filename"]
  end
end
