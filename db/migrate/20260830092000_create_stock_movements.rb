class CreateStockMovements < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :current_stock, :integer, null: false, default: 0
    create_table :stock_movements do |t|
      t.references :product, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :movement_type, null: false
      t.integer :quantity, null: false
      t.integer :stock_before, null: false
      t.integer :stock_after, null: false
      t.text :note, null: false
      t.string :reference_type
      t.bigint :reference_id
      t.timestamps
    end
    add_index :stock_movements, %i[reference_type reference_id]
  end
end
