require "test_helper"

class CmsContentTypesTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @regular = users(:regular_user)
  end

  test "unauthenticated user cannot access /cms/content_types" do
    get "/cms/content_types"
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "non-admin user is redirected away from /cms/content_types" do
    sign_in @regular
    get "/cms/content_types"
    assert_response :redirect
    assert_redirected_to "/"
    assert_equal "You are not authorized to access this area.", flash[:alert]
  end

  test "admin can view empty content types index" do
    sign_in @admin
    Macron::Cms::Content.delete_all

    get "/cms/content_types"
    assert_response :success
    assert_select "h1", "Content Types"
    assert_select "h3", "No content types found"
    assert_select "code", /bin\/rails macron:cms:import_content_types/
  end

  test "admin can view content types list in index" do
    sign_in @admin
    Macron::Cms::Content.delete_all
    heading = Macron::Cms::Content.create!(
      name: "heading",
      fields: { "name" => "title", "kind" => "string" },
      payload: {}
    )

    get "/cms/content_types"
    assert_response :success
    assert_select "h1", "Content Types"
    assert_select "table thead th", text: "Name"
    assert_select "table thead th", text: "Fields Summary"
    assert_select "table tbody td a", text: "heading"
    assert_select "table tbody td a", text: "Show"
    assert_select "table tbody td span", text: /title/
  end

  test "admin can view content type show page with field details" do
    sign_in @admin
    heading = Macron::Cms::Content.find_or_create_by!(name: "heading") do |c|
      c.fields = { "name" => "title", "kind" => "string" }
      c.payload = {}
    end

    get "/cms/content_types/#{heading.id}"
    assert_response :success
    assert_select "h1", "heading"
    assert_select "dd", "heading"
    assert_select "table thead th", text: "Field Name"
    assert_select "table thead th", text: "Kind / Type"
    assert_select "table tbody td", text: /title/
    assert_select "table tbody td span", text: /string/
    assert_select "code", /"name":\s*"title"/
    assert_select "a[href=?]", "/cms/content_types", text: /Back to Content Types/
  end

  test "sidebar displays content types navigation link" do
    sign_in @admin
    get "/cms/content_types"
    assert_response :success
    assert_select "aside nav a[href=?]", "/cms/content_types", text: /Content Types/
  end
end
