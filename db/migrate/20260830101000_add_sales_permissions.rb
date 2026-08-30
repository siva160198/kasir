class AddSalesPermissions < ActiveRecord::Migration[8.1]
  KEYS = { "sales.create" => [ "Buat transaksi", "Melakukan transaksi kasir." ], "sales.view_own" => [ "Lihat transaksi sendiri", "Melihat transaksi kasir sendiri." ], "sales.view_all" => [ "Lihat semua transaksi", "Melihat seluruh riwayat transaksi." ] }.freeze
  def up
    KEYS.each { |key, values| Permission.find_or_initialize_by(key: key).update!(name: values[0], description: values[1]) }
    Role.find_by(key: "admin")&.tap { |role| role.permissions |= Permission.where(key: KEYS.keys) }
  end
  def down = Permission.where(key: KEYS.keys).destroy_all
end
