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
      assert_includes table_btn["onclick"], 'return confirm('
      assert_includes table_btn["onclick"], 'Special'
    end

    # Show view
    get "/cms/articles/#{article.slug}"
    assert_response :success
    assert_select "form button[data-turbo-confirm=?]", expected_confirm
    assert_select "form button" do |buttons|
      show_btn = buttons.find { |b| b.text.strip == "Delete" }
      assert show_btn
      assert_includes show_btn["onclick"], 'return confirm('
      assert_includes show_btn["onclick"], 'Special'
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
end
