# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_31_111000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_approvals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "action_key", null: false
    t.datetime "approved_at"
    t.bigint "approver_id"
    t.datetime "consumed_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "payload_digest", null: false
    t.jsonb "payload_summary", default: {}, null: false
    t.bigint "requester_id", null: false
    t.datetime "updated_at", null: false
    t.index ["action_key", "payload_digest", "requester_id"], name: "index_admin_approvals_lookup"
    t.index ["approver_id"], name: "index_admin_approvals_on_approver_id"
    t.index ["expires_at"], name: "index_admin_approvals_on_expires_at"
    t.index ["requester_id"], name: "index_admin_approvals_on_requester_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_id"
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.string "chain_key", default: "legacy", null: false
    t.datetime "created_at", null: false
    t.string "entry_digest"
    t.string "ip_address"
    t.jsonb "metadata", default: {}, null: false
    t.string "previous_digest"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index "((metadata ->> 'email_digest'::text))", name: "index_audit_logs_on_email_digest_metadata", where: "((action)::text = 'session.login_failed'::text)"
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["action"], name: "index_audit_logs_on_action_trigram", opclass: :gin_trgm_ops, using: :gin
    t.index ["actor_id"], name: "index_audit_logs_on_actor_id"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["auditable_type"], name: "index_audit_logs_on_auditable_type_trigram", opclass: :gin_trgm_ops, using: :gin
    t.index ["chain_key", "id"], name: "index_audit_logs_on_chain_key_and_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["entry_digest"], name: "index_audit_logs_on_entry_digest", unique: true
    t.index ["ip_address"], name: "index_audit_logs_on_ip_address_trigram", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "cash_movements", force: :cascade do |t|
    t.bigint "amount", null: false
    t.bigint "cashier_shift_id", null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.string "movement_type", null: false
    t.text "note", null: false
    t.bigint "reference_id"
    t.string "reference_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["cashier_shift_id"], name: "index_cash_movements_on_cashier_shift_id"
    t.index ["user_id"], name: "index_cash_movements_on_user_id"
  end

  create_table "cashier_shifts", force: :cascade do |t|
    t.bigint "actual_cash"
    t.bigint "cash_difference"
    t.datetime "closed_at"
    t.text "closing_note"
    t.datetime "created_at", null: false
    t.bigint "expected_cash"
    t.datetime "opened_at", null: false
    t.bigint "opening_cash", default: 0, null: false
    t.text "opening_note"
    t.string "shift_number", null: false
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["shift_number"], name: "index_cashier_shifts_on_shift_number", unique: true
    t.index ["user_id"], name: "index_cashier_shifts_on_user_id"
    t.index ["user_id"], name: "index_one_open_shift_per_user", unique: true, where: "((status)::text = 'open'::text)"
  end

  create_table "categories", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_categories_on_lower_name", unique: true
  end

  create_table "email_change_challenges", force: :cascade do |t|
    t.integer "attempts_count", default: 0, null: false
    t.string "code_digest", null: false
    t.datetime "consumed_at"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.datetime "expires_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["expires_at"], name: "index_email_change_challenges_on_expires_at"
    t.index ["user_id"], name: "index_email_change_challenges_on_user_id"
  end

  create_table "goods_receipt_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "goods_receipt_id", null: false
    t.bigint "purchase_order_item_id", null: false
    t.integer "quantity", null: false
    t.datetime "updated_at", null: false
    t.index ["goods_receipt_id"], name: "index_goods_receipt_items_on_goods_receipt_id"
    t.index ["purchase_order_item_id"], name: "index_goods_receipt_items_on_purchase_order_item_id"
  end

  create_table "goods_receipts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "note"
    t.bigint "purchase_order_id", null: false
    t.string "receipt_number", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["purchase_order_id"], name: "index_goods_receipts_on_purchase_order_id"
    t.index ["receipt_number"], name: "index_goods_receipts_on_receipt_number", unique: true
    t.index ["user_id"], name: "index_goods_receipts_on_user_id"
  end

  create_table "login_attempts", force: :cascade do |t|
    t.boolean "captcha_verified", default: false, null: false
    t.datetime "created_at", null: false
    t.string "device_digest"
    t.string "email_digest", null: false
    t.string "ip_address", null: false
    t.integer "risk_score", default: 0, null: false
    t.boolean "successful", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_login_attempts_on_created_at"
    t.index ["device_digest", "created_at"], name: "index_login_attempts_on_device_digest_and_created_at"
    t.index ["email_digest", "created_at"], name: "index_login_attempts_on_email_digest_and_created_at"
    t.index ["ip_address", "created_at"], name: "index_login_attempts_on_ip_address_and_created_at"
  end

  create_table "login_challenges", force: :cascade do |t|
    t.integer "attempts_count", default: 0, null: false
    t.string "code_digest", null: false
    t.datetime "consumed_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["expires_at"], name: "index_login_challenges_on_expires_at"
    t.index ["user_id"], name: "index_login_challenges_on_user_id"
  end

  create_table "password_histories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "created_at"], name: "index_password_histories_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_password_histories_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "amount", null: false
    t.bigint "change_amount", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "payment_method", null: false
    t.bigint "received_amount", null: false
    t.string "reference_number"
    t.bigint "sale_id", null: false
    t.datetime "updated_at", null: false
    t.index ["sale_id"], name: "index_payments_on_sale_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_permissions_on_key", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "barcode"
    t.bigint "category_id", null: false
    t.bigint "cost_price", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "current_stock", default: 0, null: false
    t.integer "minimum_stock", default: 0, null: false
    t.string "name", null: false
    t.bigint "preferred_supplier_id"
    t.bigint "selling_price", default: 0, null: false
    t.string "sku", null: false
    t.string "unit", default: "pcs", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_products_on_lower_name"
    t.index "lower((sku)::text)", name: "index_products_on_lower_sku", unique: true
    t.index ["barcode"], name: "index_products_on_barcode", unique: true, where: "(barcode IS NOT NULL)"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["preferred_supplier_id"], name: "index_products_on_preferred_supplier_id"
  end

  create_table "purchase_order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.bigint "purchase_order_id", null: false
    t.integer "quantity", null: false
    t.integer "received_quantity", default: 0, null: false
    t.bigint "subtotal", null: false
    t.bigint "unit_cost", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_purchase_order_items_on_product_id"
    t.index ["purchase_order_id"], name: "index_purchase_order_items_on_purchase_order_id"
  end

  create_table "purchase_orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "notes"
    t.string "order_number", null: false
    t.date "ordered_at"
    t.string "payment_status", default: "unpaid", null: false
    t.string "status", default: "draft", null: false
    t.bigint "supplier_id", null: false
    t.bigint "total", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["order_number"], name: "index_purchase_orders_on_order_number", unique: true
    t.index ["supplier_id"], name: "index_purchase_orders_on_supplier_id"
    t.index ["user_id"], name: "index_purchase_orders_on_user_id"
  end

  create_table "role_permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "permission_id", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_role_permissions_on_role_id_and_permission_id", unique: true
    t.index ["role_id"], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.string "name", null: false
    t.boolean "system", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["description"], name: "index_roles_on_description_trigram", opclass: :gin_trgm_ops, using: :gin
    t.index ["key"], name: "index_roles_on_key", unique: true
    t.index ["key"], name: "index_roles_on_key_trigram", opclass: :gin_trgm_ops, using: :gin
    t.index ["name"], name: "index_roles_on_name_trigram", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "sale_items", force: :cascade do |t|
    t.bigint "cost_price", null: false
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.string "product_name", null: false
    t.integer "quantity", null: false
    t.bigint "sale_id", null: false
    t.string "sku", null: false
    t.bigint "subtotal", null: false
    t.bigint "unit_price", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_sale_items_on_product_id"
    t.index ["sale_id"], name: "index_sale_items_on_sale_id"
  end

  create_table "sale_refund_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "quantity", null: false
    t.bigint "sale_item_id", null: false
    t.bigint "sale_refund_id", null: false
    t.bigint "subtotal", null: false
    t.bigint "unit_price", null: false
    t.datetime "updated_at", null: false
    t.index ["sale_item_id"], name: "index_sale_refund_items_on_sale_item_id"
    t.index ["sale_refund_id"], name: "index_sale_refund_items_on_sale_refund_id"
  end

  create_table "sale_refunds", force: :cascade do |t|
    t.bigint "cashier_shift_id", null: false
    t.datetime "created_at", null: false
    t.text "reason", null: false
    t.string "refund_number", null: false
    t.string "refund_type", default: "partial", null: false
    t.bigint "requested_by_id", null: false
    t.text "review_note"
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.bigint "sale_id", null: false
    t.string "status", default: "pending", null: false
    t.bigint "total", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["cashier_shift_id"], name: "index_sale_refunds_on_cashier_shift_id"
    t.index ["refund_number"], name: "index_sale_refunds_on_refund_number", unique: true
    t.index ["requested_by_id"], name: "index_sale_refunds_on_requested_by_id"
    t.index ["reviewed_by_id"], name: "index_sale_refunds_on_reviewed_by_id"
    t.index ["sale_id"], name: "index_sale_refunds_on_sale_id"
    t.index ["status"], name: "index_sale_refunds_on_status"
  end

  create_table "sales", force: :cascade do |t|
    t.bigint "cashier_shift_id", null: false
    t.string "client_token", null: false
    t.datetime "completed_at", null: false
    t.datetime "created_at", null: false
    t.bigint "discount", default: 0, null: false
    t.text "notes"
    t.bigint "rounding_amount", default: 0, null: false
    t.string "sale_number", null: false
    t.string "status", default: "completed", null: false
    t.bigint "subtotal", null: false
    t.bigint "tax_amount", default: 0, null: false
    t.bigint "total", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["cashier_shift_id"], name: "index_sales_on_cashier_shift_id"
    t.index ["client_token"], name: "index_sales_on_client_token", unique: true
    t.index ["sale_number"], name: "index_sales_on_sale_number", unique: true
    t.index ["user_id"], name: "index_sales_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "ip_address"
    t.datetime "last_seen_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["expires_at"], name: "index_sessions_on_expires_at"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "step_up_challenges", force: :cascade do |t|
    t.integer "attempts_count", default: 0, null: false
    t.string "code_digest", null: false
    t.datetime "consumed_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "purpose", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["expires_at"], name: "index_step_up_challenges_on_expires_at"
    t.index ["user_id", "purpose"], name: "index_step_up_challenges_on_user_id_and_purpose"
    t.index ["user_id"], name: "index_step_up_challenges_on_user_id"
  end

  create_table "step_up_grants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "authentication_version", null: false
    t.datetime "consumed_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "purpose", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["expires_at"], name: "index_step_up_grants_on_expires_at"
    t.index ["user_id"], name: "index_step_up_grants_on_user_id"
  end

  create_table "stock_movements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "movement_type", null: false
    t.text "note", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", null: false
    t.bigint "reference_id"
    t.string "reference_type"
    t.integer "stock_after", null: false
    t.integer "stock_before", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["product_id"], name: "index_stock_movements_on_product_id"
    t.index ["reference_type", "reference_id"], name: "index_stock_movements_on_reference_type_and_reference_id"
    t.index ["user_id"], name: "index_stock_movements_on_user_id"
  end

  create_table "store_settings", force: :cascade do |t|
    t.text "address"
    t.datetime "created_at", null: false
    t.string "currency", default: "IDR", null: false
    t.string "email"
    t.string "phone"
    t.boolean "prices_include_tax", default: true, null: false
    t.integer "printer_copies", default: 1, null: false
    t.string "printer_name"
    t.string "receipt_footer", default: "Terima kasih", null: false
    t.string "receipt_header"
    t.integer "receipt_width", default: 58, null: false
    t.integer "rounding_unit", default: 1, null: false
    t.boolean "show_cashier", default: true, null: false
    t.boolean "show_sku", default: false, null: false
    t.boolean "show_tax", default: true, null: false
    t.string "store_name", default: "KASIR", null: false
    t.string "tax_id"
    t.decimal "tax_rate", precision: 5, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
  end

  create_table "suppliers", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "address"
    t.string "contact_name"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_suppliers_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "authentication_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.datetime "email_verified_at"
    t.integer "failed_login_attempts", default: 0, null: false
    t.string "first_name", limit: 80
    t.string "last_name", limit: 80
    t.bigint "last_totp_counter"
    t.datetime "locked_until"
    t.string "password_digest", null: false
    t.string "pending_email_revert_address"
    t.string "pending_email_revert_digest"
    t.datetime "pending_email_revert_expires_at"
    t.string "pending_totp_secret"
    t.text "phone"
    t.jsonb "recovery_code_digests", default: [], null: false
    t.string "role", default: "member", null: false
    t.datetime "security_alerted_at"
    t.datetime "totp_enabled_at"
    t.string "totp_secret"
    t.datetime "updated_at", null: false
    t.string "webauthn_user_handle"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["email_address"], name: "index_users_on_email_address_trigram", opclass: :gin_trgm_ops, using: :gin
    t.index ["webauthn_user_handle"], name: "index_users_on_webauthn_user_handle", unique: true
  end

  create_table "webauthn_credentials", force: :cascade do |t|
    t.string "authenticator_attachment"
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.datetime "last_used_at"
    t.string "nickname", null: false
    t.text "public_key", null: false
    t.integer "sign_count", default: 0, null: false
    t.jsonb "transports", default: [], null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["external_id"], name: "index_webauthn_credentials_on_external_id", unique: true
    t.index ["user_id"], name: "index_webauthn_credentials_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admin_approvals", "users", column: "approver_id"
  add_foreign_key "admin_approvals", "users", column: "requester_id"
  add_foreign_key "audit_logs", "users", column: "actor_id"
  add_foreign_key "cash_movements", "cashier_shifts"
  add_foreign_key "cash_movements", "users"
  add_foreign_key "cashier_shifts", "users"
  add_foreign_key "email_change_challenges", "users"
  add_foreign_key "goods_receipt_items", "goods_receipts"
  add_foreign_key "goods_receipt_items", "purchase_order_items"
  add_foreign_key "goods_receipts", "purchase_orders"
  add_foreign_key "goods_receipts", "users"
  add_foreign_key "login_challenges", "users"
  add_foreign_key "password_histories", "users"
  add_foreign_key "payments", "sales"
  add_foreign_key "products", "categories", on_delete: :restrict
  add_foreign_key "products", "suppliers", column: "preferred_supplier_id"
  add_foreign_key "purchase_order_items", "products"
  add_foreign_key "purchase_order_items", "purchase_orders"
  add_foreign_key "purchase_orders", "suppliers"
  add_foreign_key "purchase_orders", "users"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "sale_items", "products"
  add_foreign_key "sale_items", "sales"
  add_foreign_key "sale_refund_items", "sale_items"
  add_foreign_key "sale_refund_items", "sale_refunds"
  add_foreign_key "sale_refunds", "cashier_shifts"
  add_foreign_key "sale_refunds", "sales"
  add_foreign_key "sale_refunds", "users", column: "requested_by_id"
  add_foreign_key "sale_refunds", "users", column: "reviewed_by_id"
  add_foreign_key "sales", "cashier_shifts"
  add_foreign_key "sales", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "step_up_challenges", "users"
  add_foreign_key "step_up_grants", "users"
  add_foreign_key "stock_movements", "products"
  add_foreign_key "stock_movements", "users"
  add_foreign_key "users", "roles", column: "role", primary_key: "key"
  add_foreign_key "webauthn_credentials", "users"
end
