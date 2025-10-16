require_relative "lib/round_robin_assignment/version"

Gem::Specification.new do |spec|
  spec.name          = "round_robin_assignment"
  spec.version       = RoundRobinAssignment::VERSION
  spec.authors       = ["Mustafa"]
  spec.email         = ["mustafa@example.com"]

  spec.summary       = "A robust and flexible round-robin assignment system for Rails applications"
  spec.description   = "A database-backed round-robin assignment system with support for multiple groups, persistent state, and dynamic assignee lists. Perfect for distributing tasks, assignments, or work items evenly across team members."
  spec.homepage      = "https://github.com/yourusername/round_robin_assignment"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yourusername/round_robin_assignment"
  spec.metadata["changelog_uri"] = "https://github.com/yourusername/round_robin_assignment/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "activerecord", ">= 5.2"
  spec.add_dependency "activesupport", ">= 5.2"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "sqlite3", "~> 2.1"
end
