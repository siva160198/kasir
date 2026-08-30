class CreateCategoriesAndProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :categories, "lower(name)", unique: true, name: "index_categories_on_lower_name"

    create_table :products do |t|
      t.references :category, null: false, foreign_key: { on_delete: :restrict }
      t.string :name, null: false
      t.string :sku, null: false
      t.string :barcode
      t.bigint :cost_price, null: false, default: 0
      t.bigint :selling_price, null: false, default: 0
      t.integer :minimum_stock, null: false, default: 0
      t.string :unit, null: false, default: "pcs"
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :products, "lower(sku)", unique: true, name: "index_products_on_lower_sku"
    add_index :products, :barcode, unique: true, where: "barcode IS NOT NULL"
    add_index :products, "lower(name)", name: "index_products_on_lower_name"
  end
end
