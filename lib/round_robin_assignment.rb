require "active_record"
require "active_support/all"
require_relative "round_robin_assignment/version"
require_relative "round_robin_assignment/model"

module RoundRobinAssignment
  class Error < StandardError; end

  class << self
    # Returns the next assignee ID in the round-robin rotation
    # @param group_name [String] The assignment group identifier
    # @param assignee_ids [Array<Integer>] Array of assignee IDs to rotate through
    # @return [Integer, nil] The next assignee ID, or nil if assignee_ids is empty
    def get_next_assignee(group_name, assignee_ids)
      return nil if assignee_ids.nil? || assignee_ids.empty?

      # Sort for consistency
      sorted_ids = assignee_ids.sort

      # Find or create the assignment record
      assignment = Model.find_or_initialize_by(assignment_group: group_name)

      # Determine the next assignee
      next_assignee_id = if assignment.new_record?
        # First assignment - start from beginning
        sorted_ids.first
      elsif !sorted_ids.include?(assignment.last_assigned_user_id)
        # Last assignee no longer in list - find next logical assignee
        # Find the next ID that would have been after the removed one
        next_id = sorted_ids.find { |id| id > assignment.last_assigned_user_id }
        next_id || sorted_ids.first
      else
        # Get the next ID in rotation
        current_index = sorted_ids.index(assignment.last_assigned_user_id)
        next_index = (current_index + 1) % sorted_ids.length
        sorted_ids[next_index]
      end

      # Update the assignment record
      assignment.last_assigned_user_id = next_assignee_id
      assignment.last_assigned_at = Time.current
      assignment.assignment_count = (assignment.assignment_count || 0) + 1
      assignment.save!

      next_assignee_id
    end

    # Resets the assignment history for a group
    # @param group_name [String] The assignment group to reset
    # @return [Boolean] True if the group was found and deleted
    def reset_group(group_name)
      Model.where(assignment_group: group_name).destroy_all
      true
    end

    # Returns statistics for an assignment group
    # @param group_name [String] The assignment group to get stats for
    # @return [Hash, nil] Statistics hash or nil if group doesn't exist
    def group_stats(group_name)
      assignment = Model.find_by(assignment_group: group_name)
      return nil unless assignment

      {
        last_assigned_user_id: assignment.last_assigned_user_id,
        last_assigned_at: assignment.last_assigned_at,
        total_assignments: assignment.assignment_count
      }
    end

    # Delegate ActiveRecord methods to Model
    def method_missing(method, *args, &block)
      if Model.respond_to?(method)
        Model.public_send(method, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      Model.respond_to?(method) || super
    end
  end
end
