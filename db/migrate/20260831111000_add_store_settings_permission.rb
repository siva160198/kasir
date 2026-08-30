class AddStoreSettingsPermission < ActiveRecord::Migration[8.1]
  def up
    permission = Permission.find_or_initialize_by(key: "store_settings.manage")
    permission.update!(name: "Kelola pengaturan toko", description: "Mengatur profil, pajak, printer, dan struk toko.")
    Role.where(key: %w[admin manager]).find_each { |role| role.permissions |= [ permission ] }
  end
  def down = Permission.where(key: "store_settings.manage").destroy_all
end
