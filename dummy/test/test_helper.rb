ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    def count_queries(&block)
      count = 0
      counter = ->(*, payload) {
        count += 1 unless %w[SCHEMA TRANSACTION].include?(payload[:name]) ||
                          payload[:sql].match?(/\A\s*(BEGIN|COMMIT|ROLLBACK|RELEASE SAVEPOINT|SAVEPOINT)/i)
      }
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
      count
    end
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers
  end
end
