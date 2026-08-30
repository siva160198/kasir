class CreateStoreSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :store_settings do |t|
      t.string :store_name, null: false, default: "KASIR"
      t.text :address
      t.string :phone
      t.string :email
      t.string :tax_id
      t.string :currency, null: false, default: "IDR"
      t.decimal :tax_rate, precision: 5, scale: 2, null: false, default: 0
      t.boolean :prices_include_tax, null: false, default: true
      t.integer :rounding_unit, null: false, default: 1
      t.integer :receipt_width, null: false, default: 58
      t.string :receipt_header
      t.string :receipt_footer, null: false, default: "Terima kasih"
      t.boolean :show_cashier, null: false, default: true
      t.boolean :show_sku, null: false, default: false
      t.boolean :show_tax, null: false, default: true
      t.string :printer_name
      t.integer :printer_copies, null: false, default: 1
      t.timestamps
    end
    add_column :sales, :tax_amount, :bigint, null: false, default: 0
    add_column :sales, :rounding_amount, :bigint, null: false, default: 0
  end
end
