require "bundler/setup"
require "active_record"
require "round_robin_assignment"

# Setup in-memory SQLite database for testing
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

# Load the schema
ActiveRecord::Schema.define do
  create_table :round_robin_assignments, force: true do |t|
    t.string :assignment_group, null: false
    t.integer :last_assigned_user_id, null: false
    t.datetime :last_assigned_at, null: false
    t.integer :assignment_count, default: 0, null: false

    t.timestamps
  end

  add_index :round_robin_assignments, :assignment_group, unique: true
  add_index :round_robin_assignments, :last_assigned_user_id
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Clean up database between tests
  config.before(:each) do
    RoundRobinAssignment::Model.delete_all
  end
end
