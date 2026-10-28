require "test_helper"

class CmsArticlesTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @regular = users(:regular_user)
  end

  test "unauthenticated user cannot access /cms/articles" do
    get "/cms/articles"
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "non-admin user is redirected away from /cms/articles" do
    sign_in @regular
    get "/cms/articles"
    assert_response :redirect
    assert_redirected_to "/"
    assert_equal "You are not authorized to access this area.", flash[:alert]
  end

  test "admin can view articles index and sees layout elements" do
    Macron::Cms::Article.create!(title: "Getting Started", name: "getting-started")
    sign_in @admin
    get "/cms/articles"
    assert_response :success
    assert_select "h1", /Articles/
    assert_select "aside", /MacronCMS/
    assert_select "aside", /Dashboard/
    assert_select "aside", /Articles/

    # Verify table headers and absence of identifier/slug column
    assert_select "table thead th", text: "Title"
    assert_select "table thead th", text: "Created At"
    assert_select "table thead th", text: "Actions"
    assert_select "table thead th", text: /Identifier|Slug/, count: 0

    # Verify actions contain Show, Edit, Delete and Delete is an inline form
    assert_select "table tbody td a", text: "Show"
    assert_select "table tbody td a", text: "Edit"
    assert_select "table tbody td form.inline button", text: "Delete"
  end

  test "admin can create a new article" do
    sign_in @admin
    get "/cms/articles/new"
    assert_response :success
    assert_select "h1", "Create New Article"

    assert_difference("Macron::Cms::Article.count", 1) do
      post "/cms/articles", params: {
        article: {
          title: "Tailwind CMS Guide",
          name: "tailwind-cms-guide",
          meta_title: "Guide to Tailwind CMS",
          meta_description: "Learn how to use Tailwind with Macron CMS."
        }
      }
    end

    article = Macron::Cms::Article.find_by(name: "tailwind-cms-guide")
    assert_not_nil article
    assert_equal "tailwind-cms-guide", article.slug
    assert_equal "Guide to Tailwind CMS", article.meta_title
    assert_equal "Learn how to use Tailwind with Macron CMS.", article.meta_description
    assert_redirected_to "/cms/articles/#{article.slug}"
    follow_redirect!
    assert_response :success
    assert_select "h1", "Tailwind CMS Guide"
    assert_select ".rounded-xl", /Article was successfully created\./
  end

  test "admin can create a new article without providing identifier name" do
    sign_in @admin
    get "/cms/articles/new"
    assert_response :success
    assert_select "input[name='article[name]']:not([required])"

    assert_difference("Macron::Cms::Article.count", 1) do
      post "/cms/articles", params: {
        article: {
          title: "Auto Slug Generated Guide",
          name: ""
        }
      }
    end

    article = Macron::Cms::Article.find_by(name: "auto-slug-generated-guide")
    assert_not_nil article
    assert_equal "auto-slug-generated-guide", article.slug
    assert_redirected_to "/cms/articles/#{article.slug}"
  end

  test "admin can edit and update an article" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Original Title", name: "original-name")

    get "/cms/articles/#{article.slug}/edit"
    assert_response :success
    assert_select "h1", "Edit Article"

    patch "/cms/articles/#{article.slug}", params: {
      article: {
        title: "Updated Title",
        meta_title: "Updated SEO Title",
        meta_description: "Updated SEO Description"
      }
    }

    assert_redirected_to "/cms/articles/#{article.slug}"
    article.reload
    assert_equal "Updated Title", article.title
    assert_equal "Updated SEO Title", article.meta_title
    assert_equal "Updated SEO Description", article.meta_description
    follow_redirect!
    assert_select ".rounded-xl", /Article was successfully updated\./
  end

  test "admin can delete an article" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "To Be Deleted", name: "to-be-deleted")

    assert_difference("Macron::Cms::Article.count", -1) do
      delete "/cms/articles/#{article.slug}"
    end

    assert_redirected_to "/cms/articles"
    follow_redirect!
    assert_select ".rounded-xl", /Article was successfully deleted\./
  end

  test "delete buttons in table and show view include confirmation dialog with article title" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: 'Special "Guide" Article', name: "special-guide-article")
    expected_confirm = %(Are you sure you want to delete "Special "Guide" Article"?)

    # Table view on articles index
    get "/cms/articles"
    assert_response :success
    assert_select "form.inline button[data-turbo-confirm=?]", expected_confirm
    assert_select "form.inline button" do |buttons|
      table_btn = buttons.find { |b| b.text.strip == "Delete" }
      assert table_btn
      assert_includes table_btn["onclick"], "return confirm("
      assert_includes table_btn["onclick"], "Special"
    end

    # Show view
    get "/cms/articles/#{article.slug}"
    assert_response :success
    assert_select "form button[data-turbo-confirm=?]", expected_confirm
    assert_select "form button" do |buttons|
      show_btn = buttons.find { |b| b.text.strip == "Delete" }
      assert show_btn
      assert_includes show_btn["onclick"], "return confirm("
      assert_includes show_btn["onclick"], "Special"
    end
  end

  test "dashboard displays correct article count and links" do
    sign_in @admin
    Macron::Cms::Article.delete_all
    article = Macron::Cms::Article.create!(title: "Dashboard Showcase", name: "dashboard-showcase")

    get "/cms"
    assert_response :success
    assert_select "h1", "CMS Dashboard"
    assert_select "dd", "1"
    assert_select "td", "Dashboard Showcase"
    assert_select "a[href=?]", "/cms/articles/new"

    # Verify table headers and absence of slug column
    assert_select "table thead th", text: "Title"
    assert_select "table thead th", text: "Created At"
    assert_select "table thead th", text: "Actions"
    assert_select "table thead th", text: /Slug/, count: 0

    # Verify actions contain Show, Edit, Delete and Delete is an inline form
    assert_select "table tbody td a", text: "Show"
    assert_select "table tbody td a", text: "Edit"
    assert_select "table tbody td form.inline button", text: "Delete"
  end

  test "articles index and dashboard render shared empty state when no articles exist" do
    sign_in @admin
    Macron::Cms::Article.delete_all

    get "/cms/articles"
    assert_response :success
    assert_select "h3", "No articles found"
    assert_select "p", "Create your first article to begin managing content."
    assert_select "a[href=?]", "/cms/articles/new", text: /Create First Article/

    get "/cms"
    assert_response :success
    assert_select "h3", "No articles found"
    assert_select "p", "Create your first article to begin managing content."
    assert_select "a[href=?]", "/cms/articles/new", text: /Create First Article/
  end

  test "article show view displays header breadcrumb with links and stretches full width" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Breadcrumb Test Article", name: "breadcrumb-test-article")

    get "/cms/articles/#{article.slug}"
    assert_response :success

    # Top header breadcrumb
    assert_select "header nav[aria-label='Breadcrumb']" do
      assert_select "span", text: "MacronCMS"
      assert_select "a[href=?]", "/cms/articles", text: "Articles"
      assert_select "span", text: "Breadcrumb Test Article"
    end

    # No duplicate breadcrumbs in main content
    assert_select "main nav", count: 0

    # Content stretched without max-w-4xl constraint
    assert_select ".max-w-4xl", count: 0

    # Record Information card contains only Record ID and Title
    assert_select "dt", text: "Record ID"
    assert_select "dt", text: "Title"
    assert_select "dt", text: "Identifier (Name)", count: 0
    assert_select "dt", text: "Friendly URL Slug", count: 0
    assert_select "dt", text: "Created At", count: 0
    assert_select "dt", text: "Last Updated", count: 0
  end

  test "article new and edit views display header breadcrumbs and no duplicate in-page breadcrumbs" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Edit Breadcrumb Article", name: "edit-breadcrumb-article")

    # New view
    get "/cms/articles/new"
    assert_response :success
    assert_select "header nav[aria-label='Breadcrumb']" do
      assert_select "span", text: "MacronCMS"
      assert_select "a[href=?]", "/cms/articles", text: "Articles"
      assert_select "span", text: "New Article"
    end
    assert_select "main nav", count: 0

    # Edit view
    get "/cms/articles/#{article.slug}/edit"
    assert_response :success
    assert_select "header nav[aria-label='Breadcrumb']" do
      assert_select "span", text: "MacronCMS"
      assert_select "a[href=?]", "/cms/articles", text: "Articles"
      assert_select "a[href=?]", "/cms/articles/#{article.slug}", text: "Edit Breadcrumb Article"
      assert_select "span", text: "Edit"
    end
    assert_select "main nav", count: 0
  end

  test "admin can add a content block to an article and dynamic fields are populated into payload" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Block Showcase", name: "block-showcase")
    content_type = Macron::Cms::Content.create!(
      name: "heading",
      fields: [
        { "name" => "title", "kind" => "string" },
        { "name" => "level", "kind" => "string" }
      ]
    )

    get "/cms/articles/#{article.slug}"
    assert_response :success
    assert_select "h2", "Article Content Blocks"
    assert_select "select#new_content_type_select"
    assert_select "form[action=?]", "/cms/articles/#{article.slug}/article_contents"

    assert_difference -> { article.article_contents.count }, 1 do
      post "/cms/articles/#{article.slug}/article_contents", params: {
        article_content: {
          content_id: content_type.id,
          payload: {
            "title" => "Hero Section Heading",
            "level" => "h1",
            "unpermitted_key" => "should_be_stripped"
          }
        }
      }
    end

    assert_redirected_to "/cms/articles/#{article.slug}"
    follow_redirect!
    assert_select ".rounded-xl", /Content block was successfully added\./

    block = article.article_contents.last
    assert_equal 1, block.sort_order
    assert_equal "Hero Section Heading", block.payload["title"]
    assert_equal "h1", block.payload["level"]
    assert_nil block.payload["unpermitted_key"]

    # Verify rendered on show page
    assert_select "#article-content-#{block.id}" do
      assert_select ".position-badge", "#1"
      assert_select "span", text: "heading"
      assert_select "dd", text: /Hero Section Heading/
      assert_select "dd", text: /h1/
    end
  end

  test "admin can edit and update a content block payload inline" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Editable Article", name: "editable-article")
    content_type = Macron::Cms::Content.create!(
      name: "paragraph",
      fields: [ { "name" => "content", "kind" => "text" } ]
    )
    block = Macron::Cms::ArticleContent.create!(
      article: article,
      content: content_type,
      payload: { "content" => "Old content paragraph" }
    )

    patch "/cms/articles/#{article.slug}/article_contents/#{block.id}", params: {
      article_content: {
        payload: { "content" => "Updated content paragraph body text" }
      }
    }

    assert_redirected_to "/cms/articles/#{article.slug}"
    follow_redirect!
    assert_select ".rounded-xl", /Content block was successfully updated\./

    block.reload
    assert_equal "Updated content paragraph body text", block.payload["content"]
  end

  test "admin can delete a content block from an article and remaining blocks renormalize sort_order" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Deletable Article", name: "deletable-article")
    ct = Macron::Cms::Content.create!(name: "heading", fields: [ { "name" => "title", "kind" => "string" } ])

    block1 = Macron::Cms::ArticleContent.create!(article: article, content: ct, sort_order: 1)
    block2 = Macron::Cms::ArticleContent.create!(article: article, content: ct, sort_order: 2)
    block3 = Macron::Cms::ArticleContent.create!(article: article, content: ct, sort_order: 3)

    assert_difference -> { article.article_contents.count }, -1 do
      delete "/cms/articles/#{article.slug}/article_contents/#{block2.id}"
    end

    assert_redirected_to "/cms/articles/#{article.slug}"
    follow_redirect!
    assert_select ".rounded-xl", /Content block was successfully removed\./

    assert_equal [ block1.id, block3.id ], article.article_contents.pluck(:id)
    assert_equal [ 1, 2 ], article.article_contents.pluck(:sort_order)
  end

  test "admin can move content blocks up and down" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Movable Article", name: "movable-article")
    ct = Macron::Cms::Content.create!(name: "heading", fields: [ { "name" => "title", "kind" => "string" } ])

    block1 = Macron::Cms::ArticleContent.create!(article: article, content: ct, sort_order: 1, payload: { "title" => "One" })
    block2 = Macron::Cms::ArticleContent.create!(article: article, content: ct, sort_order: 2, payload: { "title" => "Two" })

    # Move down block 1
    patch "/cms/articles/#{article.slug}/article_contents/#{block1.id}/move", params: { direction: "down" }
    assert_redirected_to "/cms/articles/#{article.slug}"

    assert_equal [ block2.id, block1.id ], article.article_contents.reload.pluck(:id)
    assert_equal 1, block2.reload.sort_order
    assert_equal 2, block1.reload.sort_order

    # Move up block 1
    patch "/cms/articles/#{article.slug}/article_contents/#{block1.id}/move", params: { direction: "up" }
    assert_redirected_to "/cms/articles/#{article.slug}"

    assert_equal [ block1.id, block2.id ], article.article_contents.reload.pluck(:id)
  end

  test "reorder endpoint persists drag-and-drop order via JSON" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Drag Drop Article", name: "drag-drop-article")
    ct = Macron::Cms::Content.create!(name: "heading", fields: [ { "name" => "title", "kind" => "string" } ])

    block1 = Macron::Cms::ArticleContent.create!(article: article, content: ct, sort_order: 1)
    block2 = Macron::Cms::ArticleContent.create!(article: article, content: ct, sort_order: 2)
    block3 = Macron::Cms::ArticleContent.create!(article: article, content: ct, sort_order: 3)

    patch "/cms/articles/#{article.slug}/article_contents/reorder",
          params: { ordered_ids: [ block3.id, block1.id, block2.id ] }.to_json,
          headers: { "Content-Type" => "application/json", "Accept" => "application/json" }

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "ok", json["status"]

    assert_equal [ block3.id, block1.id, block2.id ], article.article_contents.reload.pluck(:id)
    assert_equal [ 1, 2, 3 ], [ block3.reload.sort_order, block1.reload.sort_order, block2.reload.sort_order ]
  end

  test "admin sees in-place '+' block inserters above, between, and below content blocks" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Inserter UI Article", name: "inserter-ui-article")
    ct = Macron::Cms::Content.create!(name: "heading", fields: [ { "name" => "title", "kind" => "string" } ])

    Macron::Cms::ArticleContent.create!(article: article, content: ct, sort_order: 1, payload: { "title" => "Block 1" })
    Macron::Cms::ArticleContent.create!(article: article, content: ct, sort_order: 2, payload: { "title" => "Block 2" })

    get "/cms/articles/#{article.slug}"
    assert_response :success

    # Inserter above first block (position 1)
    assert_select "#inserter-zone-top[data-position='1']" do
      assert_select "button[aria-label='Add block at position 1']"
      assert_select "#insert-slot-1"
    end

    # Inserter between block 1 and block 2 (position 2)
    assert_select ".block-inserter-zone[data-position='2']" do
      assert_select "button[aria-label='Add block at position 2']"
      assert_select "#insert-slot-2"
    end

    # Inserter after block 2 (position 3)
    assert_select ".block-inserter-zone[data-position='3']" do
      assert_select "button[aria-label='Add block at position 3']"
      assert_select "#insert-slot-3"
    end

    # Reusable Add Content Block card and hidden insert_at fields
    assert_select "#reusable-add-block-card"
    assert_select "input.insert-at-field"
  end

  test "admin sees add first block button on empty article state" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Empty Inserter Article", name: "empty-inserter-article")

    get "/cms/articles/#{article.slug}"
    assert_response :success

    assert_select "button[aria-label='Add first block']", text: /Add First Block/
    assert_select "#insert-slot-1"
  end

  test "admin can insert a content block at position 1 (above existing blocks) and existing blocks shift down" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Insert Top Article", name: "insert-top-article")
    ct = Macron::Cms::Content.create!(name: "heading", fields: [ { "name" => "title", "kind" => "string" } ])

    existing1 = Macron::Cms::ArticleContent.create!(article: article, content: ct, sort_order: 1, payload: { "title" => "Original First" })
    existing2 = Macron::Cms::ArticleContent.create!(article: article, content: ct, sort_order: 2, payload: { "title" => "Original Second" })

    assert_difference -> { article.article_contents.count }, 1 do
      post "/cms/articles/#{article.slug}/article_contents", params: {
        article_content: {
          content_id: ct.id,
          insert_at: 1,
          payload: { "title" => "New First Block" }
        }
      }
    end

    assert_redirected_to "/cms/articles/#{article.slug}"
    follow_redirect!
    assert_select ".rounded-xl", /Content block was successfully added\./

    blocks = article.article_contents.order(:sort_order, :id).to_a
    assert_equal 3, blocks.size
    assert_equal "New First Block", blocks[0].payload["title"]
    assert_equal 1, blocks[0].sort_order

    assert_equal existing1.id, blocks[1].id
    assert_equal 2, blocks[1].sort_order

    assert_equal existing2.id, blocks[2].id
    assert_equal 3, blocks[2].sort_order
  end

  test "admin can insert a content block between existing blocks and subsequent blocks shift down" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Insert Middle Article", name: "insert-middle-article")
    ct = Macron::Cms::Content.create!(name: "heading", fields: [ { "name" => "title", "kind" => "string" } ])

    block1 = Macron::Cms::ArticleContent.create!(article: article, content: ct, sort_order: 1, payload: { "title" => "Block 1" })
    block2 = Macron::Cms::ArticleContent.create!(article: article, content: ct, sort_order: 2, payload: { "title" => "Block 2" })

    assert_difference -> { article.article_contents.count }, 1 do
      post "/cms/articles/#{article.slug}/article_contents", params: {
        article_content: {
          content_id: ct.id,
          insert_at: 2,
          payload: { "title" => "Inserted Between 1 and 2" }
        }
      }
    end

    assert_redirected_to "/cms/articles/#{article.slug}"
    blocks = article.article_contents.order(:sort_order, :id).to_a
    assert_equal 3, blocks.size

    assert_equal block1.id, blocks[0].id
    assert_equal 1, blocks[0].sort_order

    assert_equal "Inserted Between 1 and 2", blocks[1].payload["title"]
    assert_equal 2, blocks[1].sort_order

    assert_equal block2.id, blocks[2].id
    assert_equal 3, blocks[2].sort_order
  end

  test "admin can insert a content block at the bottom position" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Insert Bottom Article", name: "insert-bottom-article")
    ct = Macron::Cms::Content.create!(name: "heading", fields: [ { "name" => "title", "kind" => "string" } ])

    block1 = Macron::Cms::ArticleContent.create!(article: article, content: ct, sort_order: 1, payload: { "title" => "Block 1" })
    block2 = Macron::Cms::ArticleContent.create!(article: article, content: ct, sort_order: 2, payload: { "title" => "Block 2" })

    assert_difference -> { article.article_contents.count }, 1 do
      post "/cms/articles/#{article.slug}/article_contents", params: {
        article_content: {
          content_id: ct.id,
          insert_at: 3,
          payload: { "title" => "New Bottom Block" }
        }
      }
    end

    assert_redirected_to "/cms/articles/#{article.slug}"
    blocks = article.article_contents.order(:sort_order, :id).to_a
    assert_equal 3, blocks.size

    assert_equal block1.id, blocks[0].id
    assert_equal 1, blocks[0].sort_order

    assert_equal block2.id, blocks[1].id
    assert_equal 2, blocks[1].sort_order

    assert_equal "New Bottom Block", blocks[2].payload["title"]
    assert_equal 3, blocks[2].sort_order
  end
end
