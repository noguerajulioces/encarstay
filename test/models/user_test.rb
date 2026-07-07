require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email to stripped lowercase" do
    user = User.create!(name: "Vero", email: "  VERO@Example.COM ", password: "secret123")
    assert_equal "vero@example.com", user.email
  end

  test "authenticates with the right password" do
    user = User.create!(name: "Vero", email: "vero@example.com", password: "secret123")
    assert user.authenticate("secret123")
    assert_not user.authenticate("wrong")
  end

  test "requires a unique email" do
    dup = User.new(name: "Otro", email: users(:admin).email, password: "secret123")
    assert_not dup.valid?
    assert_includes dup.errors.attribute_names, :email
  end
end
