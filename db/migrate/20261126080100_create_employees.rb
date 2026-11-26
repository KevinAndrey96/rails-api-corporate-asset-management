class CreateEmployees < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      t.string :document_number, null: false, limit: 10
      t.string :full_name, null: false, limit: 120
      t.string :email, null: false
      t.string :department, null: false, limit: 80
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :employees, :document_number, unique: true
    add_index :employees, :email, unique: true
    add_index :employees, :department
  end
end
