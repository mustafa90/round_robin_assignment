require "rails/generators"
require "rails/generators/migration"

module RoundRobinAssignment
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      def self.next_migration_number(dirname)
        if ActiveRecord::Base.timestamped_migrations
          Time.now.utc.strftime("%Y%m%d%H%M%S")
        else
          "%.3d" % (current_migration_number(dirname) + 1)
        end
      end

      def copy_migration
        migration_template "migration.rb", "db/migrate/create_round_robin_assignments.rb"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
