class CreateSuppliersAndPurchaseOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :suppliers do |t|
      t.string :name, null: false
      t.string :contact_name
      t.string :phone
      t.string :email
      t.text :address
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :suppliers, :name, unique: true

    create_table :purchase_orders do |t|
      t.references :supplier, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :order_number, null: false
      t.string :status, null: false, default: "draft"
      t.string :payment_status, null: false, default: "unpaid"
      t.bigint :total, null: false, default: 0
      t.date :ordered_at
      t.text :notes
      t.timestamps
    end
    add_index :purchase_orders, :order_number, unique: true

    create_table :purchase_order_items do |t|
      t.references :purchase_order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.integer :received_quantity, null: false, default: 0
      t.bigint :unit_cost, null: false
      t.bigint :subtotal, null: false
      t.timestamps
    end

    create_table :goods_receipts do |t|
      t.references :purchase_order, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :receipt_number, null: false
      t.text :note
      t.timestamps
    end
    add_index :goods_receipts, :receipt_number, unique: true

    create_table :goods_receipt_items do |t|
      t.references :goods_receipt, null: false, foreign_key: true
      t.references :purchase_order_item, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.timestamps
    end
  end
end
