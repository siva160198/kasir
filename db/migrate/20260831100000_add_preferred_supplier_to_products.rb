class AddPreferredSupplierToProducts < ActiveRecord::Migration[8.1]
  def change
    add_reference :products, :preferred_supplier, foreign_key: { to_table: :suppliers }
  end
end
