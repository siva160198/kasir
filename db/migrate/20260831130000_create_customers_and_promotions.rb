class CreateCustomersAndPromotions < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :customer_number, null: false
      t.string :name, null: false
      t.string :phone
      t.string :email
      t.text :address
      t.boolean :member, null: false, default: false
      t.integer :points, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :customers, :customer_number, unique: true
    add_index :customers, :phone, unique: true, where: "phone IS NOT NULL"

    create_table :promotions do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.string :discount_type, null: false
      t.integer :value, null: false
      t.bigint :minimum_purchase, null: false, default: 0
      t.bigint :maximum_discount
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :usage_limit
      t.integer :usage_count, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :promotions, :code, unique: true

    add_reference :sales, :customer, foreign_key: true
    add_reference :sales, :promotion, foreign_key: true
  end
end
