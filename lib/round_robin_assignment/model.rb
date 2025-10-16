module RoundRobinAssignment
  class Model < ActiveRecord::Base
    self.table_name = "round_robin_assignments"

    validates :assignment_group, presence: true, uniqueness: true
    validates :last_assigned_user_id, presence: true
    validates :last_assigned_at, presence: true
    validates :assignment_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    before_validation :set_defaults, on: :create

    private

    def set_defaults
      self.assignment_count ||= 0
      self.last_assigned_at ||= Time.current
    end
  end
end
