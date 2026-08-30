class CreateCashierShifts < ActiveRecord::Migration[8.1]
  def change
    create_table :cashier_shifts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :shift_number, null: false
      t.string :status, null: false, default: "open"
      t.datetime :opened_at, null: false
      t.datetime :closed_at
      t.bigint :opening_cash, null: false, default: 0
      t.bigint :expected_cash
      t.bigint :actual_cash
      t.bigint :cash_difference
      t.text :opening_note
      t.text :closing_note
      t.timestamps
    end
    add_index :cashier_shifts, :shift_number, unique: true
    add_index :cashier_shifts, :user_id, unique: true, where: "status = 'open'", name: "index_one_open_shift_per_user"
    create_table :cash_movements do |t|
      t.references :cashier_shift, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :movement_type, null: false
      t.bigint :amount, null: false
      t.text :note, null: false
      t.string :reference_type
      t.bigint :reference_id
      t.timestamps
    end
  end
end
