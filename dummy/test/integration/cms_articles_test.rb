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
    assert_select "input[name='article[slug]']:not([required])"

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

  test "admin article show renders dropdown field for content types with dropdown kind" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Dropdown Article", name: "dropdown-article")
    heading_type = Macron::Cms::Content.create!(
      name: "heading-dropdown",
      fields: [
        { "name" => "title", "kind" => "string" },
        {
          "name" => "level",
          "kind" => "dropdown",
          "options" => [
            { "name" => "Heading 1", "value" => "h1" },
            { "name" => "Heading 2", "value" => "h2" }
          ]
        }
      ]
    )
    block = Macron::Cms::ArticleContent.create!(
      article: article,
      content: heading_type,
      sort_order: 1,
      payload: { "title" => "My Heading", "level" => "h2" }
    )

    get "/cms/articles/#{article.slug}"
    assert_response :success

    # Check new content block form has select
    assert_select "select#new_content_#{heading_type.id}_payload_level" do
      assert_select "option[value='']", text: "Select level..."
      assert_select "option[value='h1']", text: "Heading 1"
      assert_select "option[value='h2']", text: "Heading 2"
    end

    # Check inline edit form has select with selected value
    assert_select "select#edit_article_content_#{block.id}_payload_level" do
      assert_select "option[value='h2'][selected]", text: "Heading 2"
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

  test "cms layout includes turbo_include_tags via Propshaft" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Turbo Asset Article", name: "turbo-asset-article")

    get "/cms/articles/#{article.slug}"
    assert_response :success
    assert_select "head script[type='module'][src*='turbo']"
    assert_select "#flash-messages"
  end

  test "admin can add a content block inline via Turbo Stream without full page reload" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Turbo Add Article", name: "turbo-add-article")
    ct = Macron::Cms::Content.create!(name: "heading", fields: [ { "name" => "title", "kind" => "string" } ])

    assert_difference -> { article.article_contents.count }, 1 do
      post "/cms/articles/#{article.slug}/article_contents",
           as: :turbo_stream,
           params: {
             article_content: {
               content_id: ct.id,
               insert_at: 1,
               payload: { "title" => "Live Stream Block" }
             }
           }
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type

    # Verify turbo-stream actions
    assert_select "turbo-stream[action='update'][target='content-blocks-section']"
    assert_select "turbo-stream[action='update'][target='flash-messages']"

    # Verify stream body contents
    assert_includes response.body, "Live Stream Block"
    assert_includes response.body, "Content block was successfully added."
    assert_includes response.body, "data-position=\"1\""
  end

  test "admin can move a content block inline via Turbo Stream" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Turbo Move Article", name: "turbo-move-article")
    ct = Macron::Cms::Content.create!(name: "heading", fields: [ { "name" => "title", "kind" => "string" } ])

    block1 = Macron::Cms::ArticleContent.create!(article: article, content: ct, sort_order: 1, payload: { "title" => "First" })
    block2 = Macron::Cms::ArticleContent.create!(article: article, content: ct, sort_order: 2, payload: { "title" => "Second" })

    patch "/cms/articles/#{article.slug}/article_contents/#{block1.id}/move",
          as: :turbo_stream,
          params: { direction: "down" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
    assert_select "turbo-stream[action='update'][target='content-blocks-section']"
    assert_select "turbo-stream[action='update'][target='flash-messages']"
    assert_includes response.body, "Content block order updated."

    assert_equal [ block2.id, block1.id ], article.article_contents.reload.pluck(:id)
  end

  test "admin can delete a content block inline via Turbo Stream" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Turbo Delete Article", name: "turbo-delete-article")
    ct = Macron::Cms::Content.create!(name: "heading", fields: [ { "name" => "title", "kind" => "string" } ])

    block1 = Macron::Cms::ArticleContent.create!(article: article, content: ct, sort_order: 1, payload: { "title" => "Block 1" })

    assert_difference -> { article.article_contents.count }, -1 do
      delete "/cms/articles/#{article.slug}/article_contents/#{block1.id}", as: :turbo_stream
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
    assert_select "turbo-stream[action='update'][target='content-blocks-section']"
    assert_select "turbo-stream[action='update'][target='flash-messages']"
    assert_includes response.body, "Content block was successfully removed."
    assert_includes response.body, "No content blocks yet"
  end

  test "admin can add an image content block with file attachment" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Image Block Article", name: "image-block-article")
    image_type = Macron::Cms::Content.create!(
      name: "image",
      fields: [ { "name" => "upload", "kind" => "file" }, { "name" => "size", "kind" => "dropdown" } ]
    )
    uploaded = Rack::Test::UploadedFile.new(
      StringIO.new("fake image data"),
      "image/png",
      original_filename: "banner.png"
    )

    assert_difference -> { article.article_contents.count }, 1 do
      post "/cms/articles/#{article.slug}/article_contents",
           as: :turbo_stream,
           params: {
             article_content: {
               content_id: image_type.id,
               insert_at: 1,
               payload: {
                 upload: uploaded,
                 size: "sm"
               }
             }
           }
    end

    assert_response :success
    new_block = article.article_contents.reload.first
    assert new_block.files.attached?
    assert_equal "banner.png", new_block.upload.filename.to_s
    assert_equal "banner.png", new_block.payload["upload"]
    assert_equal "sm", new_block.payload["size"]
  end

  test "admin can add an embed content block with html file attachment" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Embed Block Article", name: "embed-block-article")
    embed_type = Macron::Cms::Content.create!(
      name: "embed",
      fields: [ { "name" => "upload", "kind" => "file" }, { "name" => "size", "kind" => "dropdown" } ]
    )
    uploaded = Rack::Test::UploadedFile.new(
      StringIO.new("<div>Embedded Widget</div>"),
      "text/html",
      original_filename: "widget.html"
    )

    assert_difference -> { article.article_contents.count }, 1 do
      post "/cms/articles/#{article.slug}/article_contents",
           as: :turbo_stream,
           params: {
             article_content: {
               content_id: embed_type.id,
               insert_at: 1,
               payload: {
                 upload: uploaded,
                 size: "lg"
               }
             }
           }
    end

    assert_response :success
    new_block = article.article_contents.reload.first
    assert new_block.files.attached?
    assert_equal "widget.html", new_block.upload.filename.to_s
    assert_equal "widget.html", new_block.payload["upload"]
    assert_equal "lg", new_block.payload["size"]
  end

  test "admin can update an image block by replacing the attached file" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Replace Image Article", name: "replace-image-article")
    image_type = Macron::Cms::Content.create!(name: "image", fields: [ { "name" => "upload", "kind" => "file" } ])
    block = Macron::Cms::ArticleContent.create!(article: article, content: image_type, payload: { "upload" => "old.png" })
    old_file = Rack::Test::UploadedFile.new(StringIO.new("old"), "image/png", original_filename: "old.png")
    block.files.attach(old_file)

    new_file = Rack::Test::UploadedFile.new(StringIO.new("new"), "image/png", original_filename: "new.png")

    patch "/cms/articles/#{article.slug}/article_contents/#{block.id}",
          as: :turbo_stream,
          params: {
            article_content: {
              payload: {
                upload: new_file
              }
            }
          }

    assert_response :success
    block.reload
    assert_equal 1, block.files.count
    assert_equal "new.png", block.upload.filename.to_s
    assert_equal "new.png", block.payload["upload"]
  end

  test "admin can create and update article with background color, image and options" do
    sign_in @admin

    bg_file = Rack::Test::UploadedFile.new(StringIO.new("dummy bg"), "image/png", original_filename: "bg-art.png")

    assert_difference("Macron::Cms::Article.count", 1) do
      post "/cms/articles", params: {
        article: {
          title: "Themed Article",
          background_color: "#1e1e2f",
          text_color: "#e2e8f0",
          background_image: bg_file,
          background_options: {
            repeat: "repeat",
            size: "auto",
            position: "top",
            attachment: "fixed"
          }
        }
      }
    end

    article = Macron::Cms::Article.last
    assert_equal "#1e1e2f", article.background_color
    assert_equal "#e2e8f0", article.text_color
    assert_equal "repeat", article.background_repeat
    assert_equal "auto", article.background_size
    assert_equal "top", article.background_position
    assert_equal "fixed", article.background_attachment
    assert article.background_image.attached?

    # Verify public show page has body style with background and text color
    get "/articles/#{article.slug}"
    assert_response :success
    assert_select "body[style*='background-color: #1e1e2f;']"
    assert_select "body[style*='color: #e2e8f0;']"
    assert_select "h1[style*='color: #e2e8f0;']", text: "Themed Article"
    assert_select "body[style*='background-repeat: repeat;']"
    assert_select "body[style*='background-size: auto;']"

    # Verify edit form renders attached background image preview and valid single form
    get "/cms/articles/#{article.slug}/edit"
    assert_response :success
    assert_select "img[src*='bg-art.png']"
    assert_select "a[data-turbo-method='delete']", text: "Delete image"

    # Verify form submits updates to text_color and background options
    patch "/cms/articles/#{article.slug}", params: {
      article: {
        text_color: "#ffffff",
        background_options: {
          repeat: "repeat",
          size: "auto",
          position: "top",
          attachment: "fixed"
        }
      }
    }
    assert_redirected_to "/cms/articles/#{article.slug}"
    article.reload
    assert_equal "#ffffff", article.text_color
    assert_equal "auto", article.background_size

    # Verify purge background image
    assert_difference -> { ActiveStorage::Attachment.count }, -1 do
      delete "/cms/articles/#{article.slug}/purge_background_image"
    end
    assert_redirected_to "/cms/articles/#{article.slug}/edit"
    follow_redirect!
    assert_equal "Background image was successfully removed.", flash[:notice]
    article.reload
    assert_not article.background_image.attached?
  end

  test "admin can add, edit, and view markdown content block on public article page" do
    markdown_type = Macron::Cms::Content.find_or_create_by!(name: "markdown") do |c|
      c.fields = [ { "name" => "content", "kind" => "markdown" } ]
    end
    article = Macron::Cms::Article.create!(title: "Markdown Showcase", name: "markdown-showcase")
    sign_in @admin

    # Add markdown block
    assert_difference -> { article.article_contents.count }, 1 do
      post "/cms/articles/#{article.slug}/article_contents", params: {
        article_content: {
          content_id: markdown_type.id,
          payload: {
            content: "# Welcome to Markdown\n\nThis is **empowered** with CodeMirror and Kramdown."
          }
        }
      }
    end

    assert_redirected_to "/cms/articles/#{article.slug}"
    follow_redirect!
    assert_select "span", text: "markdown"
    assert_select "textarea[data-cms-editor='markdown']"

    block = article.article_contents.last
    assert_equal "# Welcome to Markdown\n\nThis is **empowered** with CodeMirror and Kramdown.", block.payload["content"]

    # Verify rendered markdown in the admin content block view mode
    assert_select "#view-payload-#{block.id} div.sm\\:col-span-2"
    assert_select "#view-payload-#{block.id} .prose.prose-zinc" do
      assert_select "h1", text: "Welcome to Markdown"
      assert_select "strong", text: "empowered"
    end

    # Public article rendering
    get "/articles/#{article.slug}"
    assert_response :success
    assert_select "div.prose.prose-zinc"
    assert_select "h1", text: "Welcome to Markdown"
    assert_select "strong", text: "empowered"
  end

  test "admin can add, edit, and view latex content block on public article page" do
    latex_type = Macron::Cms::Content.find_or_create_by!(name: "latex") do |c|
      c.fields = [ { "name" => "content", "kind" => "latex" } ]
    end
    article = Macron::Cms::Article.create!(title: "LaTeX Showcase", name: "latex-showcase")
    sign_in @admin

    # Add latex block
    assert_difference -> { article.article_contents.count }, 1 do
      post "/cms/articles/#{article.slug}/article_contents", params: {
        article_content: {
          content_id: latex_type.id,
          payload: {
            content: "\\int_{-\\infty}^{\\infty} e^{-x^2} dx = \\sqrt{\\pi}"
          }
        }
      }
    end

    assert_redirected_to "/cms/articles/#{article.slug}"
    follow_redirect!
    assert_select "span", text: "latex"
    assert_select "textarea[data-cms-editor='latex']"

    block = article.article_contents.last
    assert_equal "\\int_{-\\infty}^{\\infty} e^{-x^2} dx = \\sqrt{\\pi}", block.payload["content"]

    # Verify admin content block view mode has sm:col-span-2 and data-cms-latex
    assert_select "#view-payload-#{block.id} div.sm\\:col-span-2"
    assert_select "#view-payload-#{block.id} div[data-cms-latex]"

    # Public article rendering
    get "/articles/#{article.slug}"
    assert_response :success
    assert_select "div.cms-latex-widget[data-cms-latex]"
    assert_includes response.body, %(data-cms-latex="\\int_{-\\infty}^{\\infty} e^{-x^2} dx = \\sqrt{\\pi}")

    # Edit latex block
    patch "/cms/articles/#{article.slug}/article_contents/#{block.id}", params: {
      article_content: {
        payload: {
          content: "E = mc^2"
        }
      }
    }
    assert_redirected_to "/cms/articles/#{article.slug}"
    follow_redirect!
    block.reload
    assert_equal "E = mc^2", block.payload["content"]

    get "/articles/#{article.slug}"
    assert_response :success
    assert_select "div.cms-latex-widget[data-cms-latex='E = mc^2']"
  end

  test "admin can remove existing file attachment from content block" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Remove File Article", name: "remove-file-article")
    image_type = Macron::Cms::Content.find_or_create_by!(name: "image") do |c|
      c.fields = [ { "name" => "upload", "kind" => "file" }, { "name" => "size", "kind" => "dropdown" } ]
    end

    file = Rack::Test::UploadedFile.new(StringIO.new("fake-image"), "image/png", original_filename: "test.png")
    post "/cms/articles/#{article.slug}/article_contents", params: {
      article_content: {
        content_id: image_type.id,
        payload: {
          upload: file,
          size: "md"
        }
      }
    }
    assert_redirected_to "/cms/articles/#{article.slug}"
    follow_redirect!

    block = article.article_contents.last
    assert block.files.attached?
    assert_equal "test.png", block.payload["upload"]

    # Verify form renders the removal checkbox
    assert_select "input[type='checkbox'][name='article_content[remove_files][]'][value='upload']"

    # Submit update with removal checkbox checked
    patch "/cms/articles/#{article.slug}/article_contents/#{block.id}", params: {
      article_content: {
        remove_files: [ "upload" ],
        payload: {
          size: "lg"
        }
      }
    }
    assert_redirected_to "/cms/articles/#{article.slug}"
    follow_redirect!

    block.reload
    assert_not block.files.attached?, "Expected attached file to be purged"
    assert_nil block.payload["upload"], "Expected payload upload key to be cleared"
    assert_equal "lg", block.payload["size"]
  end

  test "admin can view article with compact block view toggle" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Compact View Article", name: "compact-view-article")
    quote_type = Macron::Cms::Content.find_or_create_by!(name: "three_js_quote") do |c|
      c.fields = [
        { "name" => "text", "kind" => "string" },
        { "name" => "color", "kind" => "color" },
        { "name" => "rotation_axis", "kind" => "dropdown" }
      ]
    end

    ac = Macron::Cms::ArticleContent.create!(
      article: article,
      content: quote_type,
      sort_order: 1,
      payload: {
        "text" => "I'll be the last one breathing",
        "color" => "#ffffff",
        "rotation_axis" => "y"
      }
    )

    # 1. Expanded view (default)
    get "/cms/articles/#{article.slug}"
    assert_response :success
    # Labels should be visible in expanded view
    assert_select "dt", text: /text/i
    assert_select "dt", text: /color/i
    assert_select "a[href*='view=compact']", text: /Compact/
    # Inserters present, checkboxes absent in expanded view
    assert_select "#inserter-zone-top", count: 1
    assert_select ".block-inserter-zone", count: 2
    assert_select ".block-select-checkbox", count: 0

    # 2. Compact view
    get "/cms/articles/#{article.slug}?view=compact"
    assert_response :success

    # In compact view, the view switcher marks Compact as active
    assert_select "a[href*='view=compact'].bg-white", text: /Compact/

    # Labels must be hidden
    assert_select "#view-payload-#{ac.id} dt", count: 0

    # Only top field text should be shown with line-clamp-2
    assert_select "#view-payload-#{ac.id} .line-clamp-2", text: "I'll be the last one breathing"

    # Move buttons and reorder should include view=compact
    assert_select "#content-blocks-list[data-reorder-url*='view=compact']"

    # In compact view, adding blocks is hidden (no inserters or dock)
    assert_select "#inserter-zone-top", count: 0
    assert_select ".block-inserter-zone", count: 0
    assert_select "#form-dock-storage", count: 0

    # Multi-select checkboxes must be present
    assert_select ".block-select-checkbox[data-id='#{ac.id}']", count: 1
  end

  test "reorder multiple blocks persists multi-drag order via JSON" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Multi Drag Article", name: "multi-drag-article")
    heading_type = Macron::Cms::Content.find_or_create_by!(name: "heading") do |c|
      c.fields = [ { "name" => "title", "kind" => "string" } ]
    end

    b1 = Macron::Cms::ArticleContent.create!(article: article, content: heading_type, sort_order: 1, payload: { "title" => "A" })
    b2 = Macron::Cms::ArticleContent.create!(article: article, content: heading_type, sort_order: 2, payload: { "title" => "B" })
    b3 = Macron::Cms::ArticleContent.create!(article: article, content: heading_type, sort_order: 3, payload: { "title" => "C" })
    b4 = Macron::Cms::ArticleContent.create!(article: article, content: heading_type, sort_order: 4, payload: { "title" => "D" })
    b5 = Macron::Cms::ArticleContent.create!(article: article, content: heading_type, sort_order: 5, payload: { "title" => "E" })

    # Reordering multiple blocks (e.g. moving [b1, b3] contiguously after b4 -> [b2, b4, b1, b3, b5])
    new_order = [ b2.id, b4.id, b1.id, b3.id, b5.id ]
    patch "/cms/articles/#{article.slug}/article_contents/reorder",
          params: { ordered_ids: new_order }.to_json,
          headers: { "Content-Type" => "application/json", "Accept" => "application/json" }

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "ok", json["status"]

    assert_equal new_order, article.article_contents.reload.pluck(:id)
    assert_equal [ 1, 2, 3, 4, 5 ], new_order.map { |id| Macron::Cms::ArticleContent.find(id).sort_order }
  end

  test "move action preserves view=compact parameter on redirect" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Move Compact Article", name: "move-compact-article")
    heading_type = Macron::Cms::Content.find_or_create_by!(name: "heading") do |c|
      c.fields = [ { "name" => "title", "kind" => "string" } ]
    end

    block1 = Macron::Cms::ArticleContent.create!(article: article, content: heading_type, sort_order: 1, payload: { "title" => "First" })
    block2 = Macron::Cms::ArticleContent.create!(article: article, content: heading_type, sort_order: 2, payload: { "title" => "Second" })

    patch "/cms/articles/#{article.slug}/article_contents/#{block2.id}/move", params: { direction: "up", view: "compact" }
    assert_redirected_to "/cms/articles/#{article.slug}?view=compact"
  end

  test "admin sees Convert dropdown only on convertible blocks in expanded and compact views" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Convert UI Article", name: "convert-ui-article")
    heading_type = Macron::Cms::Content.create!(
      name: "heading",
      fields: [ { "name" => "title", "kind" => "string" } ],
      convertible_to: []
    )
    three_js_image_type = Macron::Cms::Content.create!(
      name: "three_js_image",
      fields: [ { "name" => "upload", "kind" => "file" }, { "name" => "size", "kind" => "dropdown" } ],
      convertible_to: [ "image" ]
    )
    image_type = Macron::Cms::Content.create!(
      name: "image",
      fields: [ { "name" => "upload", "kind" => "file" }, { "name" => "size", "kind" => "dropdown" } ],
      convertible_to: [ "three_js_image" ]
    )

    heading_block = Macron::Cms::ArticleContent.create!(article: article, content: heading_type, sort_order: 1, payload: { "title" => "Hello" })
    image_block = Macron::Cms::ArticleContent.create!(article: article, content: image_type, sort_order: 2, payload: { "size" => "md" })

    # Expanded view
    get "/cms/articles/#{article.slug}"
    assert_response :success
    assert_select "#convert-dropdown-#{heading_block.id}", count: 0
    assert_select "#convert-dropdown-#{image_block.id}" do
      assert_select "button.convert-menu-trigger", text: /Convert/
      assert_select "#convert-menu-#{image_block.id} form[action*='target_content_id=#{three_js_image_type.id}'] button", text: /three_js_image/
    end

    # Compact view
    get "/cms/articles/#{article.slug}?view=compact"
    assert_response :success
    assert_select "#convert-dropdown-#{heading_block.id}", count: 0
    assert_select "#convert-dropdown-#{image_block.id}" do
      assert_select "#convert-menu-#{image_block.id} form[action*='view=compact'] button", text: /three_js_image/
    end
  end

  test "admin can convert image block to three_js_image and back via Turbo Stream preserving attachment and dormant payload keys" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Turbo Convert Article", name: "turbo-convert-article")
    image_type = Macron::Cms::Content.create!(
      name: "image",
      fields: [ { "name" => "upload", "kind" => "file" }, { "name" => "size", "kind" => "dropdown" } ],
      convertible_to: [ "three_js_image" ]
    )
    three_js_image_type = Macron::Cms::Content.create!(
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
      sort_order: 1,
      payload: { "upload" => "landscape.png", "size" => "lg" }
    )
    uploaded = Rack::Test::UploadedFile.new(StringIO.new("png-content"), "image/png", original_filename: "landscape.png")
    block.files.attach(uploaded)
    original_blob_id = block.upload.blob_id

    # 1. Convert image -> three_js_image via Turbo Stream
    assert_no_difference -> { Macron::Cms::ArticleContent.count } do
      patch "/cms/articles/#{article.slug}/article_contents/#{block.id}/convert",
            as: :turbo_stream,
            params: { target_content_id: three_js_image_type.id }
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
    assert_select "turbo-stream[action='update'][target='content-blocks-section']"
    assert_select "turbo-stream[action='update'][target='flash-messages']"
    assert_includes response.body, "Content block was converted to three_js_image."
    assert_includes response.body, "ring-blue-500/80"

    block.reload
    assert_equal three_js_image_type, block.content
    assert block.files.attached?
    assert_equal original_blob_id, block.upload.blob_id
    assert_equal "landscape.png", block.payload["upload"]
    assert_equal "lg", block.payload["size"]

    # 2. Customize effect on three_js_image, convert back to image, edit size, and convert back to three_js_image
    patch "/cms/articles/#{article.slug}/article_contents/#{block.id}",
          params: { article_content: { payload: { size: "lg", effect: "glitch" } } }
    assert_equal "glitch", block.reload.payload["effect"]

    patch "/cms/articles/#{article.slug}/article_contents/#{block.id}/convert",
          params: { target_content_id: image_type.id, view: "compact" }
    assert_redirected_to "/cms/articles/#{article.slug}?view=compact"
    assert_equal image_type, block.reload.content
    assert_equal original_blob_id, block.upload.blob_id

    # Edit size while in image mode — dormant "effect" key should remain intact
    patch "/cms/articles/#{article.slug}/article_contents/#{block.id}",
          params: { article_content: { payload: { size: "sm" } } }
    block.reload
    assert_equal "sm", block.payload["size"]
    assert_equal "glitch", block.payload["effect"]
    assert_equal original_blob_id, block.upload.blob_id

    # Convert back to three_js_image — both updated size and dormant effect are preserved
    patch "/cms/articles/#{article.slug}/article_contents/#{block.id}/convert",
          params: { target_content_id: three_js_image_type.id }
    block.reload
    assert_equal three_js_image_type, block.content
    assert_equal "sm", block.payload["size"]
    assert_equal "glitch", block.payload["effect"]
    assert_equal original_blob_id, block.upload.blob_id
  end

  test "convert endpoint rejects disallowed target content type" do
    sign_in @admin
    article = Macron::Cms::Article.create!(title: "Invalid Convert Article", name: "invalid-convert-article")
    image_type = Macron::Cms::Content.create!(name: "image", fields: [], convertible_to: [ "three_js_image" ])
    heading_type = Macron::Cms::Content.create!(name: "heading", fields: [])
    block = Macron::Cms::ArticleContent.create!(article: article, content: image_type)

    patch "/cms/articles/#{article.slug}/article_contents/#{block.id}/convert",
          as: :turbo_stream,
          params: { target_content_id: heading_type.id }

    assert_response :success
    assert_select "turbo-stream[action='update'][target='flash-messages']"
    assert_includes response.body, "Failed to convert content block"
    assert_equal image_type, block.reload.content
  end
end
