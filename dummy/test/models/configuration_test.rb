require "test_helper"

class ConfigurationTest < ActiveSupport::TestCase
  setup do
    Macron::Cms.reset_configuration!
  end

  teardown do
    # restore dummy app configuration
    Macron::Cms.configure do |config|
      config.user_class = "User"
      config.admin_flag = :admin
    end
  end

  test "has default user_class and admin_flag" do
    config = Macron::Cms::Configuration.new
    assert_equal "User", config.user_class
    assert_equal :admin, config.admin_flag
    assert_equal :user, config.devise_scope
    assert_equal :authenticate_user!, config.authenticate_method
    assert_equal :current_user, config.current_user_method
  end

  test "can configure custom user_class and admin_flag" do
    Macron::Cms.configure do |config|
      config.user_class = "AdminUser"
      config.admin_flag = :superadmin
    end

    assert_equal "AdminUser", Macron::Cms.configuration.user_class
    assert_equal :superadmin, Macron::Cms.configuration.admin_flag
    assert_equal :admin_user, Macron::Cms.configuration.devise_scope
    assert_equal :authenticate_admin_user!, Macron::Cms.configuration.authenticate_method
    assert_equal :current_admin_user, Macron::Cms.configuration.current_user_method
  end
end
