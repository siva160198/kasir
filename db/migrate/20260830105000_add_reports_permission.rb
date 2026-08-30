class AddReportsPermission < ActiveRecord::Migration[8.1]
  def up
    permission = Permission.find_or_initialize_by(key: "reports.view")
    permission.update!(name: "Lihat laporan", description: "Melihat dan mengekspor laporan penjualan dan laba.")
    Role.where(key: %w[admin manager]).find_each { |role| role.permissions |= [ permission ] }
  end
  def down = Permission.where(key: "reports.view").destroy_all
end
