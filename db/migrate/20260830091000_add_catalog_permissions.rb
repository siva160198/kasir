class AddCatalogPermissions < ActiveRecord::Migration[8.1]
  PERMISSIONS = {
    "categories.view" => [ "Lihat kategori", "Melihat daftar dan detail kategori produk." ],
    "categories.create" => [ "Buat kategori", "Membuat kategori produk." ],
    "categories.update" => [ "Ubah kategori", "Mengubah kategori produk." ],
    "categories.delete" => [ "Hapus kategori", "Menghapus kategori yang tidak digunakan produk." ],
    "products.view" => [ "Lihat produk", "Melihat daftar dan detail produk." ],
    "products.create" => [ "Buat produk", "Membuat produk baru." ],
    "products.update" => [ "Ubah produk", "Mengubah informasi produk." ],
    "products.delete" => [ "Hapus produk", "Menghapus produk." ]
  }.freeze

  def up
    PERMISSIONS.each do |key, (name, description)|
      Permission.find_or_initialize_by(key: key).update!(name: name, description: description)
    end
    admin = Role.find_by(key: "admin")
    admin.permissions |= Permission.where(key: PERMISSIONS.keys) if admin
  end

  def down
    Permission.where(key: PERMISSIONS.keys).destroy_all
  end
end
