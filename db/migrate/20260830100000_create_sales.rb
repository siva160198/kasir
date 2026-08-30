class CreateSales < ActiveRecord::Migration[8.1]
  def change
    create_table :sales do |t|
      t.references :cashier_shift, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :sale_number, null: false
      t.string :client_token, null: false
      t.string :status, null: false, default: "completed"
      t.bigint :subtotal, null: false
      t.bigint :discount, null: false, default: 0
      t.bigint :total, null: false
      t.datetime :completed_at, null: false
      t.text :notes
      t.timestamps
    end
    add_index :sales, :sale_number, unique: true
    add_index :sales, :client_token, unique: true
    create_table :sale_items do |t|
      t.references :sale, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.string :product_name, null: false
      t.string :sku, null: false
      t.integer :quantity, null: false
      t.bigint :unit_price, null: false
      t.bigint :cost_price, null: false
      t.bigint :subtotal, null: false
      t.timestamps
    end
    create_table :payments do |t|
      t.references :sale, null: false, foreign_key: true
      t.string :payment_method, null: false
      t.bigint :amount, null: false
      t.bigint :received_amount, null: false
      t.bigint :change_amount, null: false, default: 0
      t.string :reference_number
      t.timestamps
    end
  end
end
