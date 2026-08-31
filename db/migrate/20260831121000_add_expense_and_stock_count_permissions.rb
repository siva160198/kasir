class AddExpenseAndStockCountPermissions < ActiveRecord::Migration[8.1]
  PERMISSIONS = {
    "expenses.view" => [ "Lihat pengeluaran", "Melihat pengeluaran operasional." ],
    "expenses.create" => [ "Buat pengeluaran", "Mencatat pengeluaran operasional." ],
    "expenses.update" => [ "Ubah pengeluaran", "Mengubah pengeluaran operasional." ],
    "expenses.delete" => [ "Hapus pengeluaran", "Menghapus pengeluaran operasional." ],
    "stock_counts.view" => [ "Lihat stock opname", "Melihat sesi dan hasil stock opname." ],
    "stock_counts.create" => [ "Buat stock opname", "Membuat sesi stock opname." ],
    "stock_counts.update" => [ "Hitung stock opname", "Mengisi dan finalisasi stock opname." ]
  }.freeze

  def up
    admin = Role.find_by(key: "admin")
    manager = Role.find_by(key: "manager")
    PERMISSIONS.each do |key, (name, description)|
      permission = Permission.find_or_create_by!(key: key) { |p| p.assign_attributes(name: name, description: description) }
      [ admin, manager ].compact.each { |role| RolePermission.find_or_create_by!(role: role, permission: permission) }
    end
  end

  def down
    Permission.where(key: PERMISSIONS.keys).destroy_all
  end
end
