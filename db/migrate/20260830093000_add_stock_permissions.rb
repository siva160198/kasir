class AddStockPermissions < ActiveRecord::Migration[8.1]
  KEYS = { "inventory.view" => [ "Lihat persediaan", "Melihat stok produk." ], "stock_adjustments.create" => [ "Sesuaikan stok", "Membuat penyesuaian stok." ], "stock_movements.view" => [ "Lihat pergerakan stok", "Melihat jurnal stok." ] }.freeze
  def up
    KEYS.each { |key, values| Permission.find_or_initialize_by(key: key).update!(name: values[0], description: values[1]) }
    Role.find_by(key: "admin")&.tap { |role| role.permissions |= Permission.where(key: KEYS.keys) }
  end
  def down = Permission.where(key: KEYS.keys).destroy_all
end
