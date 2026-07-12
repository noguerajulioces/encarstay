require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email to stripped lowercase" do
    user = User.create!(name: "Vero", email: "  VERO@Example.COM ", password: "secret123", password_confirmation: "secret123")
    assert_equal "vero@example.com", user.email
  end

  test "authenticates with the right password" do
    user = User.create!(name: "Vero", email: "vero@example.com", password: "secret123", password_confirmation: "secret123")
    assert user.authenticate("secret123")
    assert_not user.authenticate("wrong")
  end

  test "requires a unique email" do
    dup = User.new(name: "Otro", email: users(:admin).email, password: "secret123", password_confirmation: "secret123")
    assert_not dup.valid?
    assert_includes dup.errors.attribute_names, :email
  end

  test "requires passwords with at least eight characters" do
    user = User.new(name: "Otro", email: "otro@example.com", password: "short", password_confirmation: "short")

    assert_not user.valid?
    assert_includes user.errors.attribute_names, :password
  end

  test "requires password confirmation when setting a password" do
    user = User.new(name: "Otro", email: "otro@example.com", password: "secret123")

    assert_not user.valid?
    assert_includes user.errors.attribute_names, :password_confirmation
  end

  test "can only be removed by another user" do
    admin = users(:admin)
    another_admin = User.create!(name: "Otro", email: "otro@example.com", password: "secret123", password_confirmation: "secret123")

    assert another_admin.removable_by?(admin)
    assert_not admin.removable_by?(admin)
  end
end
