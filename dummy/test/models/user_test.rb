require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "admin defaults to false" do
    user = User.new(email: "test@example.com", password: "password123")
    assert_not user.admin?
  end

  test "can be set to admin" do
    user = User.new(email: "admin@example.com", password: "password123", admin: true)
    assert user.admin?
  end
end
