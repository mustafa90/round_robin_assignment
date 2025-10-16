require "spec_helper"

RSpec.describe RoundRobinAssignment do
  it "has a version number" do
    expect(RoundRobinAssignment::VERSION).not_to be nil
  end

  describe ".get_next_assignee" do
    context "with a new assignment group" do
      it "returns the first assignee in the list" do
        assignee_ids = [1, 2, 3]
        result = RoundRobinAssignment.get_next_assignee("test_group", assignee_ids)
        expect(result).to eq(1)
      end

      it "sorts assignee IDs for consistency" do
        assignee_ids = [3, 1, 2]
        result = RoundRobinAssignment.get_next_assignee("test_group", assignee_ids)
        expect(result).to eq(1)
      end
    end

    context "with existing assignment history" do
      it "rotates through assignees in order" do
        assignee_ids = [1, 2, 3]

        expect(RoundRobinAssignment.get_next_assignee("test_group", assignee_ids)).to eq(1)
        expect(RoundRobinAssignment.get_next_assignee("test_group", assignee_ids)).to eq(2)
        expect(RoundRobinAssignment.get_next_assignee("test_group", assignee_ids)).to eq(3)
        expect(RoundRobinAssignment.get_next_assignee("test_group", assignee_ids)).to eq(1)
      end

      it "wraps around to the beginning after reaching the end" do
        assignee_ids = [10, 20]

        expect(RoundRobinAssignment.get_next_assignee("wrap_test", assignee_ids)).to eq(10)
        expect(RoundRobinAssignment.get_next_assignee("wrap_test", assignee_ids)).to eq(20)
        expect(RoundRobinAssignment.get_next_assignee("wrap_test", assignee_ids)).to eq(10)
      end
    end

    context "with dynamic assignee lists" do
      it "handles removed assignees gracefully" do
        assignee_ids = [1, 2, 3]

        expect(RoundRobinAssignment.get_next_assignee("dynamic_group", assignee_ids)).to eq(1)
        expect(RoundRobinAssignment.get_next_assignee("dynamic_group", assignee_ids)).to eq(2)

        # Remove assignee 2
        assignee_ids = [1, 3]
        expect(RoundRobinAssignment.get_next_assignee("dynamic_group", assignee_ids)).to eq(3)
        expect(RoundRobinAssignment.get_next_assignee("dynamic_group", assignee_ids)).to eq(1)
      end

      it "handles added assignees" do
        assignee_ids = [1, 2]

        expect(RoundRobinAssignment.get_next_assignee("dynamic_group", assignee_ids)).to eq(1)
        expect(RoundRobinAssignment.get_next_assignee("dynamic_group", assignee_ids)).to eq(2)

        # Add assignee 3
        assignee_ids = [1, 2, 3]
        expect(RoundRobinAssignment.get_next_assignee("dynamic_group", assignee_ids)).to eq(3)
        expect(RoundRobinAssignment.get_next_assignee("dynamic_group", assignee_ids)).to eq(1)
      end

      it "resets when last assignee is no longer in the list" do
        assignee_ids = [1, 2, 3]

        expect(RoundRobinAssignment.get_next_assignee("reset_group", assignee_ids)).to eq(1)
        expect(RoundRobinAssignment.get_next_assignee("reset_group", assignee_ids)).to eq(2)

        # Completely different set of assignees
        assignee_ids = [10, 20, 30]
        expect(RoundRobinAssignment.get_next_assignee("reset_group", assignee_ids)).to eq(10)
      end
    end

    context "with multiple assignment groups" do
      it "maintains separate state for each group" do
        group1_ids = [1, 2, 3]
        group2_ids = [10, 20, 30]

        expect(RoundRobinAssignment.get_next_assignee("group1", group1_ids)).to eq(1)
        expect(RoundRobinAssignment.get_next_assignee("group2", group2_ids)).to eq(10)
        expect(RoundRobinAssignment.get_next_assignee("group1", group1_ids)).to eq(2)
        expect(RoundRobinAssignment.get_next_assignee("group2", group2_ids)).to eq(20)
        expect(RoundRobinAssignment.get_next_assignee("group1", group1_ids)).to eq(3)
        expect(RoundRobinAssignment.get_next_assignee("group2", group2_ids)).to eq(30)
      end
    end

    context "with edge cases" do
      it "returns nil for empty assignee list" do
        result = RoundRobinAssignment.get_next_assignee("empty_group", [])
        expect(result).to be_nil
      end

      it "returns nil for nil assignee list" do
        result = RoundRobinAssignment.get_next_assignee("nil_group", nil)
        expect(result).to be_nil
      end

      it "handles single assignee" do
        assignee_ids = [42]

        expect(RoundRobinAssignment.get_next_assignee("single_group", assignee_ids)).to eq(42)
        expect(RoundRobinAssignment.get_next_assignee("single_group", assignee_ids)).to eq(42)
        expect(RoundRobinAssignment.get_next_assignee("single_group", assignee_ids)).to eq(42)
      end

      it "handles large numbers of assignees" do
        assignee_ids = (1..100).to_a
        results = []

        100.times do
          results << RoundRobinAssignment.get_next_assignee("large_group", assignee_ids)
        end

        expect(results).to eq(assignee_ids)
      end
    end

    context "persistence and state" do
      it "increments assignment count" do
        assignee_ids = [1, 2, 3]

        3.times { RoundRobinAssignment.get_next_assignee("count_group", assignee_ids) }

        stats = RoundRobinAssignment.group_stats("count_group")
        expect(stats[:total_assignments]).to eq(3)
      end

      it "updates last_assigned_at timestamp" do
        assignee_ids = [1, 2, 3]

        time_before = Time.current - 1.second
        RoundRobinAssignment.get_next_assignee("time_group", assignee_ids)
        time_after = Time.current + 1.second

        stats = RoundRobinAssignment.group_stats("time_group")
        expect(stats[:last_assigned_at]).to be_between(time_before, time_after)
      end
    end
  end

  describe ".reset_group" do
    it "removes all records for the specified group" do
      assignee_ids = [1, 2, 3]

      RoundRobinAssignment.get_next_assignee("reset_test", assignee_ids)
      RoundRobinAssignment.get_next_assignee("reset_test", assignee_ids)

      expect(RoundRobinAssignment::Model.where(assignment_group: "reset_test").exists?).to be true

      RoundRobinAssignment.reset_group("reset_test")

      expect(RoundRobinAssignment::Model.where(assignment_group: "reset_test").exists?).to be false
    end

    it "resets the rotation to the beginning" do
      assignee_ids = [1, 2, 3]

      expect(RoundRobinAssignment.get_next_assignee("reset_rotation", assignee_ids)).to eq(1)
      expect(RoundRobinAssignment.get_next_assignee("reset_rotation", assignee_ids)).to eq(2)

      RoundRobinAssignment.reset_group("reset_rotation")

      expect(RoundRobinAssignment.get_next_assignee("reset_rotation", assignee_ids)).to eq(1)
    end

    it "doesn't affect other groups" do
      group1_ids = [1, 2, 3]
      group2_ids = [10, 20, 30]

      RoundRobinAssignment.get_next_assignee("group1", group1_ids)
      RoundRobinAssignment.get_next_assignee("group2", group2_ids)

      RoundRobinAssignment.reset_group("group1")

      expect(RoundRobinAssignment::Model.where(assignment_group: "group1").exists?).to be false
      expect(RoundRobinAssignment::Model.where(assignment_group: "group2").exists?).to be true
    end
  end

  describe ".group_stats" do
    context "when group exists" do
      it "returns statistics hash" do
        assignee_ids = [1, 2, 3]

        RoundRobinAssignment.get_next_assignee("stats_group", assignee_ids)
        RoundRobinAssignment.get_next_assignee("stats_group", assignee_ids)

        stats = RoundRobinAssignment.group_stats("stats_group")

        expect(stats).to be_a(Hash)
        expect(stats[:last_assigned_user_id]).to eq(2)
        expect(stats[:total_assignments]).to eq(2)
        expect(stats[:last_assigned_at]).to be_a(Time)
      end

      it "reflects current state accurately" do
        assignee_ids = [10, 20, 30, 40]

        4.times { RoundRobinAssignment.get_next_assignee("accurate_stats", assignee_ids) }

        stats = RoundRobinAssignment.group_stats("accurate_stats")

        expect(stats[:last_assigned_user_id]).to eq(40)
        expect(stats[:total_assignments]).to eq(4)
      end
    end

    context "when group doesn't exist" do
      it "returns nil" do
        stats = RoundRobinAssignment.group_stats("nonexistent_group")
        expect(stats).to be_nil
      end
    end
  end

  describe "ActiveRecord delegation" do
    it "delegates where queries to Model" do
      assignee_ids = [1, 2, 3]

      RoundRobinAssignment.get_next_assignee("delegation_test", assignee_ids)

      result = RoundRobinAssignment.where(assignment_group: "delegation_test")
      expect(result.count).to eq(1)
    end

    it "delegates find_by to Model" do
      assignee_ids = [1, 2, 3]

      RoundRobinAssignment.get_next_assignee("find_test", assignee_ids)

      result = RoundRobinAssignment.find_by(assignment_group: "find_test")
      expect(result).not_to be_nil
      expect(result.assignment_group).to eq("find_test")
    end

    it "delegates all to Model" do
      assignee_ids = [1, 2, 3]

      RoundRobinAssignment.get_next_assignee("group1", assignee_ids)
      RoundRobinAssignment.get_next_assignee("group2", assignee_ids)

      all_records = RoundRobinAssignment.all
      expect(all_records.count).to eq(2)
    end
  end

  describe "Model validations" do
    it "requires assignment_group" do
      model = RoundRobinAssignment::Model.new(
        last_assigned_user_id: 1,
        last_assigned_at: Time.current
      )

      expect(model.valid?).to be false
      expect(model.errors[:assignment_group]).to include("can't be blank")
    end

    it "requires unique assignment_group" do
      RoundRobinAssignment::Model.create!(
        assignment_group: "unique_test",
        last_assigned_user_id: 1,
        last_assigned_at: Time.current
      )

      model = RoundRobinAssignment::Model.new(
        assignment_group: "unique_test",
        last_assigned_user_id: 2,
        last_assigned_at: Time.current
      )

      expect(model.valid?).to be false
      expect(model.errors[:assignment_group]).to include("has already been taken")
    end

    it "requires last_assigned_user_id" do
      model = RoundRobinAssignment::Model.new(
        assignment_group: "test",
        last_assigned_at: Time.current
      )

      expect(model.valid?).to be false
      expect(model.errors[:last_assigned_user_id]).to include("can't be blank")
    end

    it "requires last_assigned_at" do
      model = RoundRobinAssignment::Model.new(
        assignment_group: "test",
        last_assigned_user_id: 1,
        last_assigned_at: nil
      )

      # Skip the callback to test validation directly
      model.define_singleton_method(:set_defaults) {}
      expect(model.valid?).to be false
      expect(model.errors[:last_assigned_at]).to include("can't be blank")
    end

    it "validates assignment_count is an integer >= 0" do
      model = RoundRobinAssignment::Model.new(
        assignment_group: "test",
        last_assigned_user_id: 1,
        last_assigned_at: Time.current,
        assignment_count: -1
      )

      expect(model.valid?).to be false
      expect(model.errors[:assignment_count]).to include("must be greater than or equal to 0")
    end
  end
end
