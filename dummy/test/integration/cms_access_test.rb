require "test_helper"

class CmsAccessTest < ActionDispatch::IntegrationTest
  test "unauthenticated user is redirected to sign in" do
    get "/cms"
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "authenticated non-admin user is redirected to root with alert" do
    sign_in users(:regular_user)
    get "/cms"
    assert_response :redirect
    assert_redirected_to "/"
    assert_equal "You are not authorized to access this area.", flash[:alert]
  end

  test "authenticated admin user can access /cms and sees dashboard" do
    sign_in users(:admin_user)
    get "/cms"
    assert_response :success
    assert_select "h1", "CMS Dashboard"
  end

  test "custom admin_flag configuration is respected" do
    sign_in users(:admin_user)

    original_flag = Macron::Cms.configuration.admin_flag
    begin
      # Configure a non-existent or false-returning flag
      Macron::Cms.configuration.admin_flag = :non_existent_flag
      get "/cms"
      assert_response :redirect
      assert_redirected_to "/"
      assert_equal "You are not authorized to access this area.", flash[:alert]
    ensure
      Macron::Cms.configuration.admin_flag = original_flag
    end
  end
end
