class CreateAssets < ActiveRecord::Migration[8.1]
  def change
    create_table :assets do |t|
      t.string :tag, null: false, limit: 12
      t.integer :category, null: false
      t.integer :status, null: false, default: 0
      t.string :brand, null: false, limit: 60
      t.string :model, null: false, limit: 80
      t.string :serial_number, limit: 60
      t.date :purchased_on, null: false
      t.bigint :purchase_cost, null: false
      t.string :plate, limit: 6
      t.date :soat_expires_on
      t.date :technical_review_expires_on

      t.timestamps
    end
    add_index :assets, :tag, unique: true
    add_index :assets, :serial_number, unique: true
    add_index :assets, :plate, unique: true
    add_index :assets, %i[category status]
    add_check_constraint :assets, "purchase_cost > 0", name: "assets_purchase_cost_positive"
  end
end
