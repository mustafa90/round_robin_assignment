# RoundRobinAssignment

A robust and flexible round-robin assignment system for Rails applications with ActiveRecord support. Perfect for distributing tasks, assignments, or work items evenly across team members or resources.

## Features

- **Persistent State**: Tracks assignment history in the database
- **Multiple Groups**: Support for independent round-robin queues via assignment groups
- **Flexible Assignment Lists**: Dynamically adjust assignee lists without losing rotation state
- **Edge Case Handling**: Gracefully handles removed assignees and empty lists
- **Thread-Safe**: Database-backed persistence ensures consistency across concurrent processes
- **Full Test Coverage**: Battle-tested with comprehensive RSpec tests

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'round_robin_assignment'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install round_robin_assignment
```

After installation, run the generator to create the required migration:

```bash
$ rails generate round_robin_assignment:install
$ rails db:migrate
```

## Usage

### Basic Usage

```ruby
# Define your assignee list (user IDs, employee IDs, etc.)
assignee_ids = [1, 2, 3, 4, 5]

# Get the next assignee in rotation
next_assignee_id = RoundRobinAssignment.get_next_assignee('support_team', assignee_ids)
# => 1 (first assignment)

next_assignee_id = RoundRobinAssignment.get_next_assignee('support_team', assignee_ids)
# => 2 (second assignment)

# ... continues through 3, 4, 5, then back to 1
```

### Multiple Assignment Groups

You can maintain separate round-robin queues for different purposes:

```ruby
# Customer support team rotation
RoundRobinAssignment.get_next_assignee('support_team', [1, 2, 3])

# Sales lead distribution
RoundRobinAssignment.get_next_assignee('sales_leads', [10, 11, 12, 13])

# Code review assignments
RoundRobinAssignment.get_next_assignee('code_reviews', [20, 21, 22])
```

### Real-World Example: Job Assignment

```ruby
class OpportunityAssignmentJob < ApplicationJob
  COMPLIANCE_TEAM_IDS = {
    6 => 'Michelle Simmons',
    471 => 'Lynn Fraga',
    3794 => 'Mykenna Hawkins'
  }.freeze

  def perform(opportunity)
    assignee_ids = COMPLIANCE_TEAM_IDS.keys

    # Get next team member in rotation
    next_assignee_id = RoundRobinAssignment.get_next_assignee(
      'compliance_team_vetting',
      assignee_ids
    )

    if next_assignee_id
      opportunity.update!(assignee_id: next_assignee_id)

      Rails.logger.info(
        "Assigned #{COMPLIANCE_TEAM_IDS[next_assignee_id]} to opportunity #{opportunity.id}"
      )

      # Send notification
      notify_assignee(next_assignee_id, opportunity)
    end
  end
end
```

### Dynamic Assignee Lists

The gem handles changes to assignee lists gracefully:

```ruby
# Initial team
RoundRobinAssignment.get_next_assignee('team', [1, 2, 3])  # => 1
RoundRobinAssignment.get_next_assignee('team', [1, 2, 3])  # => 2

# Team member 2 goes on vacation, removed from rotation
RoundRobinAssignment.get_next_assignee('team', [1, 3])     # => 3
RoundRobinAssignment.get_next_assignee('team', [1, 3])     # => 1

# New team member joins
RoundRobinAssignment.get_next_assignee('team', [1, 3, 4])  # => 3
RoundRobinAssignment.get_next_assignee('team', [1, 3, 4])  # => 4
```

### Statistics and Management

```ruby
# Get statistics for an assignment group
stats = RoundRobinAssignment.group_stats('support_team')
# => {
#      last_assigned_user_id: 3,
#      last_assigned_at: 2024-01-15 10:30:00,
#      total_assignments: 150
#    }

# Reset a group's assignment history
RoundRobinAssignment.reset_group('support_team')

# Check if a group exists
RoundRobinAssignment.where(assignment_group: 'support_team').exists?
```

### Advanced Usage: Custom Assignment Logic

```ruby
class WorkloadBalancedAssignment
  def self.get_next_assignee(team_ids)
    # Get basic round-robin assignment
    next_id = RoundRobinAssignment.get_next_assignee('team', team_ids)

    # Check workload (example)
    if User.find(next_id).current_workload > 10
      # Skip to next person if overloaded
      team_ids_without_current = team_ids - [next_id]
      if team_ids_without_current.any?
        next_id = RoundRobinAssignment.get_next_assignee('team', team_ids_without_current)
      end
    end

    next_id
  end
end
```

## API Reference

### Class Methods

#### `RoundRobinAssignment.get_next_assignee(group_name, assignee_ids)`

Returns the next assignee ID in the round-robin rotation for the specified group.

**Parameters:**
- `group_name` (String): Unique identifier for the assignment group
- `assignee_ids` (Array): Array of assignee IDs to rotate through

**Returns:**
- Integer: The ID of the next assignee
- nil: If assignee_ids is empty or nil

**Example:**
```ruby
RoundRobinAssignment.get_next_assignee('support', [1, 2, 3])
```

#### `RoundRobinAssignment.reset_group(group_name)`

Removes all assignment history for the specified group.

**Parameters:**
- `group_name` (String): The assignment group to reset

**Example:**
```ruby
RoundRobinAssignment.reset_group('support')
```

#### `RoundRobinAssignment.group_stats(group_name)`

Returns statistics for the specified assignment group.

**Parameters:**
- `group_name` (String): The assignment group to get stats for

**Returns:**
- Hash: Contains `:last_assigned_user_id`, `:last_assigned_at`, `:total_assignments`
- nil: If the group doesn't exist

**Example:**
```ruby
stats = RoundRobinAssignment.group_stats('support')
puts "Last assigned to User ##{stats[:last_assigned_user_id]}"
puts "Total assignments: #{stats[:total_assignments]}"
```

## Database Schema

The gem creates a `round_robin_assignments` table with the following structure:

```ruby
create_table :round_robin_assignments do |t|
  t.string :assignment_group, null: false
  t.integer :last_assigned_user_id, null: false
  t.datetime :last_assigned_at, null: false
  t.integer :assignment_count, default: 0, null: false
  t.timestamps
end

add_index :round_robin_assignments, :assignment_group, unique: true
add_index :round_robin_assignments, :last_assigned_user_id
```

## Testing

The gem includes comprehensive RSpec tests. To run tests in your application:

```ruby
# spec/models/round_robin_assignment_spec.rb
require 'rails_helper'

RSpec.describe 'Round Robin Assignment' do
  it 'assigns users in rotation' do
    ids = [1, 2, 3]

    expect(RoundRobinAssignment.get_next_assignee('test', ids)).to eq(1)
    expect(RoundRobinAssignment.get_next_assignee('test', ids)).to eq(2)
    expect(RoundRobinAssignment.get_next_assignee('test', ids)).to eq(3)
    expect(RoundRobinAssignment.get_next_assignee('test', ids)).to eq(1)
  end
end
```

### Factory for Testing

```ruby
# spec/factories/round_robin_assignments.rb
FactoryBot.define do
  factory :round_robin_assignment do
    assignment_group { 'test_group' }
    last_assigned_user_id { 1 }
    last_assigned_at { Time.current }
    assignment_count { 1 }
  end
end
```

## Configuration (Optional)

You can configure the gem in an initializer:

```ruby
# config/initializers/round_robin_assignment.rb
RoundRobinAssignment.configure do |config|
  # Add any future configuration options here
  # config.some_option = true
end
```

## Common Use Cases

### 1. Customer Support Ticket Assignment
```ruby
class TicketAssignmentService
  def self.assign_ticket(ticket)
    available_agents = User.support_agents.on_duty.pluck(:id)
    assignee_id = RoundRobinAssignment.get_next_assignee('support_tickets', available_agents)
    ticket.update(assigned_to_id: assignee_id)
  end
end
```

### 2. Lead Distribution for Sales Team
```ruby
class LeadDistributionJob < ApplicationJob
  def perform(lead)
    sales_team_ids = User.sales_team.active.pluck(:id)
    next_sales_rep = RoundRobinAssignment.get_next_assignee('sales_leads', sales_team_ids)
    lead.assign_to(next_sales_rep)
  end
end
```

### 3. Code Review Assignment
```ruby
class PullRequestService
  def assign_reviewer(pull_request)
    eligible_reviewers = pull_request.eligible_reviewers.pluck(:id)
    reviewer_id = RoundRobinAssignment.get_next_assignee(
      "code_reviews_#{pull_request.repository_id}",
      eligible_reviewers
    )
    pull_request.update(reviewer_id: reviewer_id)
  end
end
```

### 4. On-Call Rotation
```ruby
class OnCallRotationService
  def next_on_call_engineer
    engineers = Engineer.available_for_on_call.pluck(:id)
    RoundRobinAssignment.get_next_assignee('on_call_rotation', engineers)
  end
end
```

## Monitoring and Debugging

### Check Assignment Distribution
```ruby
# See how many times each person has been assigned
def check_distribution(group_name, team_ids)
  stats = RoundRobinAssignment.group_stats(group_name)
  puts "Total assignments: #{stats[:total_assignments]}"
  puts "Last assigned to: User ##{stats[:last_assigned_user_id]}"
  puts "Last assigned at: #{stats[:last_assigned_at]}"
end
```

### Rails Console Helpers
```ruby
# Check current state
RoundRobinAssignment.all

# Find specific group
RoundRobinAssignment.find_by(assignment_group: 'support_team')

# Manual adjustment (use with caution)
assignment = RoundRobinAssignment.find_by(assignment_group: 'support_team')
assignment.update(last_assigned_user_id: 5)
```

## Performance Considerations

- **Database Queries**: Each call to `get_next_assignee` performs 1-2 database queries
- **Concurrency**: The gem uses database transactions to handle concurrent assignments
- **Scaling**: Suitable for systems with thousands of assignment groups and millions of assignments
- **Indexing**: Indexes on `assignment_group` ensure fast lookups

## Troubleshooting

### Issue: Assignments not rotating
```ruby
# Check if the group exists
RoundRobinAssignment.find_by(assignment_group: 'your_group')

# Verify the assignee list
assignee_ids = [1, 2, 3]
puts "Assignees: #{assignee_ids.inspect}"

# Test manually
3.times do
  id = RoundRobinAssignment.get_next_assignee('test_group', assignee_ids)
  puts "Assigned to: #{id}"
end
```

### Issue: Unexpected assignee selected
```ruby
# The gem always sorts IDs for consistency
[3, 1, 2] # Will be treated as [1, 2, 3]

# Check the current state
stats = RoundRobinAssignment.group_stats('your_group')
puts "Last assigned: #{stats[:last_assigned_user_id]}"
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/round_robin_assignment.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

### Development

After checking out the repo, run:

```bash
bundle install
bundle exec rspec
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Changelog

### Version 1.0.0 (Initial Release)
- Core round-robin assignment functionality
- Support for multiple assignment groups
- Dynamic assignee lists
- Statistics and reset functionality
- Comprehensive test suite

### Future Enhancements (Roadmap)
- Weighted round-robin (some assignees get more assignments)
- Time-based restrictions (business hours, vacation tracking)
- Assignment history tracking and reporting
- Web UI for managing assignments
- Webhook notifications
- Redis caching for high-volume systems

## Credits

Originally developed for production use in a CRM system handling thousands of daily assignments across multiple teams.

## Support

For questions, issues, or feature requests, please open an issue on GitHub or contact the maintainers.