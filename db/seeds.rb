# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
Role.find_or_create_by!(key: "admin") { |role| role.assign_attributes(name: "Administrator", description: "Akses penuh ke seluruh admin panel.", system: true) }
Role.find_or_create_by!(key: "member") { |role| role.assign_attributes(name: "Member", description: "Role bawaan untuk pengguna yang melakukan registrasi.", system: true) }
Role.find_or_create_by!(key: "manager") { |role| role.assign_attributes(name: "Manager", description: "Mengawasi katalog, stok, dan operasional kasir.", system: true) }
Role.find_or_create_by!(key: "cashier") { |role| role.assign_attributes(name: "Kasir", description: "Menjalankan shift dan transaksi kasir.", system: true) }

permissions = {
  "dashboard.view" => [ "Dashboard", "Melihat dashboard admin." ],
  "users.view" => [ "Lihat users", "Melihat daftar dan detail user." ],
  "users.update" => [ "Ubah users", "Mengubah role dan status user." ],
  "roles.view" => [ "Lihat roles", "Melihat daftar role dan permission." ],
  "roles.create" => [ "Buat role", "Membuat role baru dan menetapkan permission awal." ],
  "roles.update" => [ "Ubah role", "Mengubah nama, deskripsi, dan permission role." ],
  "roles.delete" => [ "Hapus role", "Menghapus role kustom yang tidak digunakan." ],
  "audit_logs.view" => [ "Lihat audit logs", "Melihat riwayat aktivitas keamanan." ],
  "sessions.view" => [ "Lihat perangkat", "Melihat perangkat dan sesi login milik sendiri." ],
  "sessions.delete" => [ "Hapus sesi", "Mengakhiri sesi login milik sendiri." ],
  "account_security.view" => [ "Lihat keamanan akun", "Melihat keamanan dan riwayat login milik sendiri." ],
  "account_security.update" => [ "Ubah keamanan akun", "Mengubah password, email, recovery code, dan passkey milik sendiri." ],
  "profile.view" => [ "Lihat profil", "Melihat profil akun sendiri." ],
  "profile.update" => [ "Ubah profil", "Mengubah foto dan informasi profil akun sendiri." ],
  "jobs.view" => [ "Lihat antrean job", "Melihat status antrean dan job gagal." ],
  "jobs.update" => [ "Kelola job gagal", "Mencoba ulang atau menghapus job gagal." ],
  "api_docs.view" => [ "Lihat dokumentasi API", "Membuka dokumentasi OpenAPI interaktif." ],
  "security_approvals.view" => [ "Lihat persetujuan keamanan", "Melihat perubahan admin yang menunggu persetujuan." ],
  "security_approvals.update" => [ "Setujui perubahan keamanan", "Menyetujui perubahan sensitif yang diajukan administrator lain." ],
  "categories.view" => [ "Lihat kategori", "Melihat daftar dan detail kategori produk." ],
  "categories.create" => [ "Buat kategori", "Membuat kategori produk." ],
  "categories.update" => [ "Ubah kategori", "Mengubah kategori produk." ],
  "categories.delete" => [ "Hapus kategori", "Menghapus kategori yang tidak digunakan produk." ],
  "products.view" => [ "Lihat produk", "Melihat daftar dan detail produk." ],
  "products.create" => [ "Buat produk", "Membuat produk baru." ],
  "products.update" => [ "Ubah produk", "Mengubah informasi produk." ],
  "products.delete" => [ "Hapus produk", "Menghapus produk." ],
  "inventory.view" => [ "Lihat persediaan", "Melihat stok produk." ],
  "stock_adjustments.create" => [ "Sesuaikan stok", "Membuat penyesuaian stok." ],
  "stock_movements.view" => [ "Lihat pergerakan stok", "Melihat jurnal stok." ],
  "cashier_shifts.view_own" => [ "Lihat shift sendiri", "Melihat shift kasir sendiri." ],
  "cashier_shifts.manage_own" => [ "Kelola shift sendiri", "Membuka dan menutup shift sendiri." ],
  "cashier_shifts.view_all" => [ "Lihat semua shift", "Melihat riwayat seluruh kasir." ],
  "sales.create" => [ "Buat transaksi", "Melakukan transaksi kasir." ],
  "sales.view_own" => [ "Lihat transaksi sendiri", "Melihat transaksi kasir sendiri." ],
  "sales.view_all" => [ "Lihat semua transaksi", "Melihat seluruh riwayat transaksi." ],
  "sales.refund_create" => [ "Ajukan retur", "Mengajukan retur atau pembatalan transaksi." ],
  "sales.refund_review" => [ "Tinjau retur", "Menyetujui atau menolak retur dan pembatalan transaksi." ],
  "reports.view" => [ "Lihat laporan", "Melihat dan mengekspor laporan penjualan dan laba." ],
  "suppliers.view" => [ "Lihat supplier", "Melihat data supplier." ], "suppliers.create" => [ "Buat supplier", "Menambah supplier." ], "suppliers.update" => [ "Ubah supplier", "Mengubah data supplier." ], "suppliers.delete" => [ "Hapus supplier", "Menghapus supplier yang belum digunakan." ],
  "purchases.view" => [ "Lihat pembelian", "Melihat pesanan pembelian." ], "purchases.create" => [ "Buat pembelian", "Membuat pesanan pembelian." ], "purchases.update" => [ "Kelola pembelian", "Mengubah, menerima, dan membatalkan pembelian." ],
  "expenses.view" => [ "Lihat pengeluaran", "Melihat pengeluaran operasional." ], "expenses.create" => [ "Buat pengeluaran", "Mencatat pengeluaran operasional." ], "expenses.update" => [ "Ubah pengeluaran", "Mengubah pengeluaran operasional." ], "expenses.delete" => [ "Hapus pengeluaran", "Menghapus pengeluaran operasional." ],
  "stock_counts.view" => [ "Lihat stock opname", "Melihat sesi dan hasil stock opname." ], "stock_counts.create" => [ "Buat stock opname", "Membuat sesi stock opname." ], "stock_counts.update" => [ "Hitung stock opname", "Mengisi dan finalisasi stock opname." ],
  "customers.view" => [ "Lihat pelanggan", "Melihat pelanggan dan riwayat belanja." ], "customers.create" => [ "Buat pelanggan", "Mendaftarkan pelanggan baru." ], "customers.update" => [ "Ubah pelanggan", "Mengubah informasi pelanggan." ], "customers.delete" => [ "Hapus pelanggan", "Menghapus pelanggan yang belum bertransaksi." ],
  "promotions.view" => [ "Lihat promosi", "Melihat daftar promosi." ], "promotions.create" => [ "Buat promosi", "Membuat kode promosi." ], "promotions.update" => [ "Ubah promosi", "Mengubah kode promosi." ], "promotions.delete" => [ "Hapus promosi", "Menghapus promosi yang belum digunakan." ],
  "store_settings.manage" => [ "Kelola pengaturan toko", "Mengatur profil, pajak, printer, dan struk toko." ]
}
permissions.each do |key, (name, description)|
  Permission.find_or_initialize_by(key: key).tap do |permission|
    permission.update!(name: name, description: description)
  end
end
Permission.where(key: "roles.manage").destroy_all
Role.find_by!(key: "admin").permissions = Permission.all
self_service_permissions = Permission.where(key: %w[sessions.view sessions.delete account_security.view account_security.update profile.view profile.update])
Role.where.not(key: "admin").find_each { |role| role.permissions |= self_service_permissions }
Role.find_by!(key: "manager").permissions |= Permission.where(key: %w[dashboard.view categories.view products.view inventory.view stock_movements.view stock_counts.view stock_counts.create stock_counts.update cashier_shifts.view_own cashier_shifts.manage_own cashier_shifts.view_all sales.view_own sales.view_all sales.refund_create sales.refund_review reports.view suppliers.view suppliers.create suppliers.update suppliers.delete purchases.view purchases.create purchases.update expenses.view expenses.create expenses.update expenses.delete customers.view customers.create customers.update customers.delete promotions.view promotions.create promotions.update promotions.delete store_settings.manage])
Role.find_by!(key: "cashier").permissions |= Permission.where(key: %w[dashboard.view cashier_shifts.view_own cashier_shifts.manage_own sales.create sales.view_own sales.refund_create customers.view customers.create])

if Rails.env.development?
  admin = User.find_or_initialize_by(email_address: ENV.fetch("ADMIN_EMAIL", "admin@kasir.local"))

  if admin.new_record?
    admin.password = ENV.fetch("ADMIN_PASSWORD") do
      raise "Set ADMIN_PASSWORD when creating the development admin"
    end
  end

  admin.role = "admin"
  admin.email_verified_at ||= Time.current
  admin.save!

  puts "Development admin ready: #{admin.email_address}"

  demo_password = ENV["DEMO_USER_PASSWORD"]
  %w[manager@kasir.local cashier1@kasir.local cashier2@kasir.local].each do |email|
    user = User.find_or_initialize_by(email_address: email)
    if user.new_record?
      raise "Set DEMO_USER_PASSWORD when creating development users" if demo_password.blank?
      user.password = demo_password
    end
    user.role = email.start_with?("manager") ? "manager" : "cashier"
    user.email_verified_at ||= Time.current
    user.save!
  end

  unless CashierShift.exists?(shift_number: "SFT-DEMO-001")
    cashier = User.find_by!(email_address: "cashier1@kasir.local")
    shift = CashierShift.create!(user: cashier, shift_number: "SFT-DEMO-001", status: "closed", opened_at: 1.day.ago.change(hour: 8), closed_at: 1.day.ago.change(hour: 16), opening_cash: 200_000, expected_cash: 200_000, actual_cash: 200_000, cash_difference: 0, opening_note: "Shift contoh", closing_note: "Kas sesuai")
    CashMovement.create!(cashier_shift: shift, user: cashier, movement_type: "opening", amount: 200_000, note: "Saldo awal shift contoh")
    CashMovement.create!(cashier_shift: shift, user: cashier, movement_type: "closing", amount: 200_000, note: "Penutupan shift contoh")
  end

  catalog = {
    "Makanan" => [
      { name: "Nasi Goreng", sku: "MKN-001", barcode: "899700100001", cost_price: 12_000, selling_price: 20_000, minimum_stock: 5, unit: "porsi" },
      { name: "Roti Cokelat", sku: "MKN-002", barcode: "899700100002", cost_price: 5_000, selling_price: 9_000, minimum_stock: 10, unit: "pcs" },
      { name: "Mi Instan", sku: "MKN-003", barcode: "899700100003", cost_price: 3_000, selling_price: 5_000, minimum_stock: 12, unit: "pcs" }
    ],
    "Minuman" => [
      { name: "Kopi Susu", sku: "MNM-001", barcode: "899700200001", cost_price: 8_000, selling_price: 15_000, minimum_stock: 8, unit: "cup" },
      { name: "Teh Manis", sku: "MNM-002", barcode: "899700200002", cost_price: 3_000, selling_price: 7_000, minimum_stock: 8, unit: "cup" },
      { name: "Air Mineral 600 ml", sku: "MNM-003", barcode: "899700200003", cost_price: 2_500, selling_price: 4_000, minimum_stock: 24, unit: "botol" }
    ],
    "Kebutuhan Harian" => [
      { name: "Gula Pasir 1 kg", sku: "KHR-001", barcode: "899700300001", cost_price: 15_000, selling_price: 18_000, minimum_stock: 6, unit: "pcs" },
      { name: "Tisu Wajah", sku: "KHR-002", barcode: "899700300002", cost_price: 9_000, selling_price: 13_000, minimum_stock: 6, unit: "box" }
    ]
  }

  catalog.each do |category_name, products|
    category = Category.find_or_create_by!(name: category_name) do |record|
      record.description = "Data contoh kategori #{category_name.downcase}."
      record.active = true
    end
    products.each do |attributes|
      Product.find_or_create_by!(sku: attributes.fetch(:sku)) do |product|
        product.assign_attributes(attributes.merge(category: category, active: true))
      end
    end
  end

  initial_stocks = { "MKN-001" => 20, "MKN-002" => 35, "MKN-003" => 50, "MNM-001" => 25, "MNM-002" => 30, "MNM-003" => 60, "KHR-001" => 10, "KHR-002" => 4 }
  initial_stocks.each do |sku, quantity|
    product = Product.find_by!(sku: sku)
    next if product.stock_movements.exists?(movement_type: "initial")
    product.update!(current_stock: quantity)
    StockMovement.create!(product: product, user: admin, movement_type: "initial", quantity: quantity, stock_before: 0, stock_after: quantity, note: "Stok awal data development")
  end

  # Dashboard demo data. The fixed marker keeps this block idempotent.
  unless Sale.exists?(client_token: "DEMO-DASHBOARD-001")
    cashier_one = User.find_by!(email_address: "cashier1@kasir.local")
    cashier_two = User.find_by!(email_address: "cashier2@kasir.local")
    cashier_one.update!(first_name: "Ayu", last_name: "Lestari")
    cashier_two.update!(first_name: "Made", last_name: "Pratama")

    products = Product.where(sku: %w[MKN-001 MKN-002 MKN-003 MNM-001 MNM-002 MNM-003 KHR-001 KHR-002]).index_by(&:sku)
    payment_methods = %w[cash qris cash debit_card transfer qris cash]
    sale_patterns = [
      [ [ "MNM-003", 2 ], [ "MKN-002", 1 ] ],
      [ [ "MKN-003", 3 ], [ "MNM-003", 1 ] ],
      [ [ "MNM-001", 2 ], [ "MKN-002", 2 ] ],
      [ [ "MKN-001", 1 ], [ "MNM-002", 2 ] ],
      [ [ "KHR-001", 1 ], [ "KHR-002", 1 ], [ "MNM-003", 2 ] ],
      [ [ "MKN-002", 3 ], [ "MNM-001", 1 ] ],
      [ [ "MKN-003", 4 ], [ "MNM-002", 1 ] ]
    ]

    7.times do |day_index|
      date = Date.current - (6 - day_index).days
      cashier = day_index.even? ? cashier_one : cashier_two
      shift = CashierShift.create!(
        user: cashier,
        shift_number: "SFT-DASH-#{day_index + 1}",
        status: "closed",
        opened_at: date.in_time_zone.change(hour: 8),
        closed_at: date.in_time_zone.change(hour: 17),
        opening_cash: 300_000,
        expected_cash: 300_000,
        actual_cash: 300_000,
        cash_difference: 0,
        opening_note: "Shift data demo dashboard",
        closing_note: "Shift selesai dan kas sesuai"
      )

      (3 + day_index).times do |sale_index|
        pattern = sale_patterns[(day_index + sale_index) % sale_patterns.length]
        completed_at = date.in_time_zone.change(hour: 9 + (sale_index % 8), min: (sale_index * 11) % 60)
        items = pattern.map do |sku, quantity|
          product = products.fetch(sku)
          { product: product, quantity: quantity, subtotal: product.selling_price * quantity }
        end
        subtotal = items.sum { |item| item.fetch(:subtotal) }
        discount = sale_index % 5 == 4 ? 2_000 : 0
        total = subtotal - discount
        number = "SALE-DEMO-#{day_index + 1}-#{format('%02d', sale_index + 1)}"
        token = day_index.zero? && sale_index.zero? ? "DEMO-DASHBOARD-001" : "DEMO-DASHBOARD-#{day_index + 1}-#{sale_index + 1}"

        sale = Sale.create!(
          cashier_shift: shift,
          user: cashier,
          sale_number: number,
          client_token: token,
          status: "completed",
          subtotal: subtotal,
          discount: discount,
          tax_amount: (total * 11.0 / 111).round,
          rounding_amount: 0,
          total: total,
          completed_at: completed_at,
          notes: "Transaksi contoh dashboard"
        )
        items.each do |item|
          product = item.fetch(:product)
          SaleItem.create!(sale: sale, product: product, product_name: product.name, sku: product.sku, quantity: item.fetch(:quantity), unit_price: product.selling_price, cost_price: product.cost_price, subtotal: item.fetch(:subtotal))
        end
        method = payment_methods[(day_index + sale_index) % payment_methods.length]
        received = method == "cash" ? ((total + 9_999) / 10_000) * 10_000 : total
        Payment.create!(sale: sale, payment_method: method, amount: total, received_amount: received, change_amount: received - total, reference_number: method == "cash" ? nil : "REF#{number.delete('-')}")
      end
    end

    CashierShift.create!(
      user: cashier_one,
      shift_number: "SFT-DEMO-AKTIF",
      status: "open",
      opened_at: Time.current.change(hour: 8, min: 0),
      opening_cash: 300_000,
      opening_note: "Shift aktif untuk tampilan dashboard"
    )

    demo_stock = { "MKN-001" => 18, "MKN-002" => 7, "MKN-003" => 42, "MNM-001" => 6, "MNM-002" => 0, "MNM-003" => 55, "KHR-001" => 4, "KHR-002" => 0 }
  demo_stock.each { |sku, quantity| products.fetch(sku).update!(current_stock: quantity) }
  end

  expense_samples = [
    [ "EXP-DEMO-001", 5.days.ago.to_date, "utilities", "Tagihan listrik toko", 475_000, "transfer" ],
    [ "EXP-DEMO-002", 3.days.ago.to_date, "supplies", "Kertas thermal dan alat tulis", 185_000, "cash" ],
    [ "EXP-DEMO-003", 1.day.ago.to_date, "transport", "Biaya pengiriman barang", 120_000, "cash" ]
  ]
  expense_samples.each do |number, date, category, description, amount, method|
    Expense.find_or_create_by!(expense_number: number) { |expense| expense.assign_attributes(user: admin, expense_date: date, category: category, description: description, amount: amount, payment_method: method, note: "Data contoh pengeluaran") }
  end

  unless StockCount.exists?(count_number: "SO-DEMO-001")
    count = StockCount.create!(created_by: admin, finalized_by: admin, count_number: "SO-DEMO-001", counted_on: 2.days.ago.to_date, status: "completed", notes: "Stock opname contoh", finalized_at: 2.days.ago)
    Product.order(:name).limit(5).each { |product| count.stock_count_items.create!(product: product, system_stock: product.current_stock, counted_stock: product.current_stock, difference: 0, unit_cost: product.cost_price) }
  end

  [ [ "CUS-DEMO-001", "Kadek Ayu", "081234567801", true, 125 ], [ "CUS-DEMO-002", "Made Wirawan", "081234567802", true, 80 ], [ "CUS-DEMO-003", "Pelanggan Umum", nil, false, 0 ] ].each do |number, name, phone, member, points|
    Customer.find_or_create_by!(customer_number: number) { |customer| customer.assign_attributes(name: name, phone: phone, member: member, points: points, active: true) }
  end
  Promotion.find_or_create_by!(code: "HEMAT10") { |promotion| promotion.assign_attributes(name: "Hemat 10 Persen", discount_type: "percentage", value: 10, minimum_purchase: 50_000, maximum_discount: 25_000, starts_at: 1.month.ago, ends_at: 1.month.from_now, usage_limit: 100, active: true) }
  Promotion.find_or_create_by!(code: "POTONG5000") { |promotion| promotion.assign_attributes(name: "Potongan Lima Ribu", discount_type: "fixed", value: 5_000, minimum_purchase: 30_000, starts_at: 1.month.ago, ends_at: 1.month.from_now, active: true) }

  [
    [ "CUS-DEMO-004", "Komang Sari", "081234567803", "komang.sari@example.com", true, 210 ],
    [ "CUS-DEMO-005", "Nyoman Aditya", "081234567804", "nyoman.aditya@example.com", true, 45 ],
    [ "CUS-DEMO-006", "Warung Merta", "081234567805", "warung.merta@example.com", false, 0 ]
  ].each do |number, name, phone, email, member, points|
    customer = Customer.find_or_initialize_by(customer_number: number)
    customer.update!(name: name, phone: phone, email: email, member: member, points: points, active: true)
  end

  expired_promotion = Promotion.find_or_initialize_by(code: "MERDEKA15")
  expired_promotion.update!(name: "Promo Merdeka 15 Persen", discount_type: "percentage", value: 15, minimum_purchase: 75_000, maximum_discount: 30_000, starts_at: 3.months.ago, ends_at: 2.months.ago, usage_limit: 50, usage_count: 18, active: false)

  store_setting = StoreSetting.current
  store_setting.update!(
    store_name: "Toko Kasir Bali",
    address: "Jl. Raya Sesetan No. 88, Denpasar, Bali",
    phone: "0812-3456-7890",
    email: "halo@tokokasir.local",
    tax_id: "01.234.567.8-901.000",
    tax_rate: 11,
    prices_include_tax: true,
    rounding_unit: 100,
    receipt_header: "Belanja mudah, harga bersahabat",
    receipt_footer: "Terima kasih. Sampai jumpa kembali!",
    receipt_width: 58,
    printer_name: "Thermal POS-58",
    printer_copies: 1,
    show_cashier: true,
    show_sku: true,
    show_tax: true
  )

  supplier_samples = [
    [ "PT Sumber Pangan Bali", "Wayan Sudarma", "08113800101", "order@sumberpangan.example", "Jl. Cargo Permai No. 12, Denpasar" ],
    [ "CV Tirta Sejahtera", "Putu Dian", "08113800102", "sales@tirtasejahtera.example", "Jl. Gatot Subroto Timur No. 45, Denpasar" ],
    [ "UD Kebutuhan Kita", "Made Arimbawa", "08113800103", "made@kebutuhankita.example", "Jl. Raya Abianbase No. 7, Badung" ],
    [ "Bali Fresh Supply", "Kadek Rina", "08113800104", "rina@balifresh.example", "Jl. By Pass Ngurah Rai No. 21, Sanur" ]
  ]
  supplier_samples.each do |name, contact_name, phone, email, address|
    supplier = Supplier.find_or_initialize_by(name: name)
    supplier.update!(contact_name: contact_name, phone: phone, email: email, address: address, active: true)
  end

  food_supplier = Supplier.find_by!(name: "PT Sumber Pangan Bali")
  drink_supplier = Supplier.find_by!(name: "CV Tirta Sejahtera")
  daily_supplier = Supplier.find_by!(name: "UD Kebutuhan Kita")
  Product.where(sku: %w[MKN-001 MKN-002 MKN-003]).update_all(preferred_supplier_id: food_supplier.id)
  Product.where(sku: %w[MNM-001 MNM-002 MNM-003]).update_all(preferred_supplier_id: drink_supplier.id)
  Product.where(sku: %w[KHR-001 KHR-002]).update_all(preferred_supplier_id: daily_supplier.id)

  purchase_samples = [
    [ "PO-DEMO-001", food_supplier, 12.days.ago.to_date, "completed", "paid", [ [ "MKN-002", 30 ], [ "MKN-003", 50 ] ] ],
    [ "PO-DEMO-002", drink_supplier, 4.days.ago.to_date, "ordered", "unpaid", [ [ "MNM-001", 24 ], [ "MNM-003", 48 ] ] ],
    [ "PO-DEMO-003", daily_supplier, Date.current, "draft", "unpaid", [ [ "KHR-001", 15 ], [ "KHR-002", 20 ] ] ]
  ]
  purchase_samples.each do |number, supplier, ordered_at, status, payment_status, item_rows|
    order = PurchaseOrder.find_or_initialize_by(order_number: number)
    total = item_rows.sum { |sku, quantity| Product.find_by!(sku: sku).cost_price * quantity }
    order.update!(supplier: supplier, user: admin, ordered_at: ordered_at, status: status, payment_status: payment_status, total: total, notes: "Data contoh pesanan pembelian")
    item_rows.each do |sku, quantity|
      product = Product.find_by!(sku: sku)
      item = order.purchase_order_items.find_or_initialize_by(product: product)
      received_quantity = status == "completed" ? quantity : 0
      item.update!(quantity: quantity, received_quantity: received_quantity, unit_cost: product.cost_price, subtotal: product.cost_price * quantity)
    end
  end

  completed_order = PurchaseOrder.find_by!(order_number: "PO-DEMO-001")
  receipt = GoodsReceipt.find_or_initialize_by(receipt_number: "GR-DEMO-001")
  receipt.update!(purchase_order: completed_order, user: admin, note: "Seluruh barang diterima dalam kondisi baik")
  completed_order.purchase_order_items.each do |order_item|
    receipt.goods_receipt_items.find_or_create_by!(purchase_order_item: order_item) { |item| item.quantity = order_item.quantity }
  end

  draft_count = StockCount.find_or_create_by!(count_number: "SO-DEMO-002") do |count|
    count.assign_attributes(created_by: admin, counted_on: Date.current, status: "draft", notes: "Stock opname rak minuman yang sedang berjalan")
  end
  Product.where(sku: %w[MNM-001 MNM-002 MNM-003]).each do |product|
    draft_count.stock_count_items.find_or_create_by!(product: product) { |item| item.assign_attributes(system_stock: product.current_stock, unit_cost: product.cost_price) }
  end

  additional_expenses = [
    [ "EXP-DEMO-004", Date.current, "maintenance", "Servis rutin printer kasir", 250_000, "cash" ],
    [ "EXP-DEMO-005", Date.current, "salary", "Uang makan staf mingguan", 600_000, "transfer" ],
    [ "EXP-DEMO-006", 2.days.ago.to_date, "other", "Biaya kebersihan toko", 150_000, "debit_card" ]
  ]
  additional_expenses.each do |number, date, category, description, amount, method|
    expense = Expense.find_or_initialize_by(expense_number: number)
    expense.update!(user: admin, expense_date: date, category: category, description: description, amount: amount, payment_method: method, note: "Data contoh pengeluaran operasional")
  end

  demo_customers = Customer.where(customer_number: %w[CUS-DEMO-001 CUS-DEMO-002 CUS-DEMO-004 CUS-DEMO-005]).to_a
  Sale.where("client_token LIKE ?", "DEMO-DASHBOARD-%").order(:completed_at).limit(16).each_with_index do |sale, index|
    sale.update_columns(customer_id: demo_customers[index % demo_customers.length].id)
  end
  promotion = Promotion.find_by!(code: "HEMAT10")
  promoted_sales = Sale.where("client_token LIKE ?", "DEMO-DASHBOARD-%").order(completed_at: :desc).limit(3)
  promoted_sales.update_all(promotion_id: promotion.id)
  promotion.update!(usage_count: promoted_sales.count)

  unless SaleRefund.exists?(refund_number: "REF-DEMO-001")
    refunded_sale = Sale.where("client_token LIKE ?", "DEMO-DASHBOARD-%").includes(:sale_items).order(:completed_at).first
    refunded_item = refunded_sale.sale_items.first
    refund = SaleRefund.create!(sale: refunded_sale, cashier_shift: refunded_sale.cashier_shift, requested_by: refunded_sale.user, refund_number: "REF-DEMO-001", refund_type: "partial", status: "pending", reason: "Produk tidak sesuai pesanan", total: refunded_item.unit_price)
    refund.sale_refund_items.create!(sale_item: refunded_item, quantity: 1, unit_price: refunded_item.unit_price, subtotal: refunded_item.unit_price)
  end

  puts "Development data ready: #{Product.count} products, #{Supplier.count} suppliers, #{PurchaseOrder.count} purchases, #{Customer.count} customers, #{Sale.count} sales"
end
