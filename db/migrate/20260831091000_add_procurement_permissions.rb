class AddProcurementPermissions < ActiveRecord::Migration[8.1]
  KEYS = {
    "suppliers.view" => [ "Lihat supplier", "Melihat data supplier." ], "suppliers.create" => [ "Buat supplier", "Menambah supplier." ], "suppliers.update" => [ "Ubah supplier", "Mengubah data supplier." ], "suppliers.delete" => [ "Hapus supplier", "Menghapus supplier yang belum digunakan." ],
    "purchases.view" => [ "Lihat pembelian", "Melihat pesanan pembelian." ], "purchases.create" => [ "Buat pembelian", "Membuat pesanan pembelian." ], "purchases.update" => [ "Kelola pembelian", "Mengubah, menerima, dan membatalkan pembelian." ]
  }.freeze
  def up
    KEYS.each { |key, values| Permission.find_or_initialize_by(key: key).update!(name: values[0], description: values[1]) }
    Role.where(key: %w[admin manager]).find_each { |role| role.permissions |= Permission.where(key: KEYS.keys) }
  end
  def down = Permission.where(key: KEYS.keys).destroy_all
end
