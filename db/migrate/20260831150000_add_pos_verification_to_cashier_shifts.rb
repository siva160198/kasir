class AddPosVerificationToCashierShifts < ActiveRecord::Migration[8.1]
  def change
    add_column :cashier_shifts, :pos_verified_at, :datetime
    add_column :cashier_shifts, :pos_verified_session_id, :bigint
    add_index :cashier_shifts, :pos_verified_session_id
  end
end
