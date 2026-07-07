ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Load all fixtures in test/fixtures/*.yml for every test.
    fixtures :all
  end
end
