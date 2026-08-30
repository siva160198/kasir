class AddShiftPermissions < ActiveRecord::Migration[8.1]
  KEYS = { "cashier_shifts.view_own" => [ "Lihat shift sendiri", "Melihat shift kasir sendiri." ], "cashier_shifts.manage_own" => [ "Kelola shift sendiri", "Membuka dan menutup shift sendiri." ], "cashier_shifts.view_all" => [ "Lihat semua shift", "Melihat riwayat seluruh kasir." ] }.freeze
  def up
    KEYS.each { |key, values| Permission.find_or_initialize_by(key: key).update!(name: values[0], description: values[1]) }
    Role.find_by(key: "admin")&.tap { |role| role.permissions |= Permission.where(key: KEYS.keys) }
  end
  def down = Permission.where(key: KEYS.keys).destroy_all
end
