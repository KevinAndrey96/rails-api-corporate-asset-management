class CreateAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :assignments do |t|
      t.references :asset, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.date :assigned_on, null: false
      t.date :due_on
      t.date :returned_on
      t.string :notes, limit: 500

      t.timestamps
    end
    add_index :assignments, :asset_id, unique: true, where: "returned_on IS NULL", name: "index_assignments_one_open_per_asset"
    add_check_constraint :assignments, "returned_on IS NULL OR returned_on >= assigned_on", name: "assignments_returned_after_assigned"
    add_check_constraint :assignments, "due_on IS NULL OR due_on >= assigned_on", name: "assignments_due_after_assigned"
  end
end
