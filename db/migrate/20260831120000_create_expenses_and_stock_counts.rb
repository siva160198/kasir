class CreateExpensesAndStockCounts < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :expense_number, null: false
      t.date :expense_date, null: false
      t.string :category, null: false
      t.string :description, null: false
      t.bigint :amount, null: false
      t.string :payment_method, null: false, default: "cash"
      t.string :reference_number
      t.text :note
      t.timestamps
    end
    add_index :expenses, :expense_number, unique: true
    add_index :expenses, :expense_date

    create_table :stock_counts do |t|
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :finalized_by, foreign_key: { to_table: :users }
      t.string :count_number, null: false
      t.string :status, null: false, default: "draft"
      t.date :counted_on, null: false
      t.text :notes
      t.datetime :finalized_at
      t.timestamps
    end
    add_index :stock_counts, :count_number, unique: true

    create_table :stock_count_items do |t|
      t.references :stock_count, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :system_stock, null: false
      t.integer :counted_stock
      t.integer :difference
      t.bigint :unit_cost, null: false, default: 0
      t.timestamps
    end
    add_index :stock_count_items, %i[stock_count_id product_id], unique: true
  end
end
