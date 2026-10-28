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
end
