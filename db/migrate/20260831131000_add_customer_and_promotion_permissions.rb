class AddCustomerAndPromotionPermissions < ActiveRecord::Migration[8.1]
  PERMISSIONS = {
    "customers.view" => [ "Lihat pelanggan", "Melihat pelanggan dan riwayat belanja." ],
    "customers.create" => [ "Buat pelanggan", "Mendaftarkan pelanggan baru." ],
    "customers.update" => [ "Ubah pelanggan", "Mengubah informasi pelanggan." ],
    "customers.delete" => [ "Hapus pelanggan", "Menghapus pelanggan yang belum bertransaksi." ],
    "promotions.view" => [ "Lihat promosi", "Melihat daftar promosi." ],
    "promotions.create" => [ "Buat promosi", "Membuat kode promosi." ],
    "promotions.update" => [ "Ubah promosi", "Mengubah kode promosi." ],
    "promotions.delete" => [ "Hapus promosi", "Menghapus promosi yang belum digunakan." ]
  }.freeze

  def up
    admin = Role.find_by(key: "admin")
    manager = Role.find_by(key: "manager")
    cashier = Role.find_by(key: "cashier")
    PERMISSIONS.each do |key, (name, description)|
      permission = Permission.find_or_create_by!(key: key) { |p| p.assign_attributes(name: name, description: description) }
      roles = key.start_with?("customers.") && %w[view create].include?(key.split(".").last) ? [ admin, manager, cashier ] : [ admin, manager ]
      roles.compact.each { |role| RolePermission.find_or_create_by!(role: role, permission: permission) }
    end
  end

  def down
    Permission.where(key: PERMISSIONS.keys).destroy_all
  end
end
