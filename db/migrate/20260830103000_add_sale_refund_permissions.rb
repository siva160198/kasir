class AddSaleRefundPermissions < ActiveRecord::Migration[8.1]
  KEYS = {
    "sales.refund_create" => [ "Ajukan retur", "Mengajukan retur atau pembatalan transaksi." ],
    "sales.refund_review" => [ "Tinjau retur", "Menyetujui atau menolak retur dan pembatalan transaksi." ]
  }.freeze

  def up
    KEYS.each { |key, values| Permission.find_or_initialize_by(key: key).update!(name: values[0], description: values[1]) }
    Role.find_by(key: "admin")&.tap { |role| role.permissions |= Permission.where(key: KEYS.keys) }
    Role.find_by(key: "manager")&.tap { |role| role.permissions |= Permission.where(key: KEYS.keys) }
    Role.find_by(key: "cashier")&.tap { |role| role.permissions |= Permission.where(key: "sales.refund_create") }
  end

  def down = Permission.where(key: KEYS.keys).destroy_all
end
