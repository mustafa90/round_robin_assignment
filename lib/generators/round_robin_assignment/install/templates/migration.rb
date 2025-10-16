class CreateRoundRobinAssignments < ActiveRecord::Migration[5.2]
  def change
    create_table :round_robin_assignments do |t|
      t.string :assignment_group, null: false
      t.integer :last_assigned_user_id, null: false
      t.datetime :last_assigned_at, null: false
      t.integer :assignment_count, default: 0, null: false

      t.timestamps
    end

    add_index :round_robin_assignments, :assignment_group, unique: true
    add_index :round_robin_assignments, :last_assigned_user_id
  end
end
