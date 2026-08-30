class CreateSaleRefunds < ActiveRecord::Migration[8.1]
  def change
    create_table :sale_refunds do |t|
      t.references :sale, null: false, foreign_key: true
      t.references :cashier_shift, null: false, foreign_key: true
      t.references :requested_by, null: false, foreign_key: { to_table: :users }
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.string :refund_number, null: false
      t.string :refund_type, null: false, default: "partial"
      t.string :status, null: false, default: "pending"
      t.bigint :total, null: false, default: 0
      t.text :reason, null: false
      t.text :review_note
      t.datetime :reviewed_at
      t.timestamps
    end
    add_index :sale_refunds, :refund_number, unique: true
    add_index :sale_refunds, :status

    create_table :sale_refund_items do |t|
      t.references :sale_refund, null: false, foreign_key: true
      t.references :sale_item, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.bigint :unit_price, null: false
      t.bigint :subtotal, null: false
      t.timestamps
    end
  end
end
