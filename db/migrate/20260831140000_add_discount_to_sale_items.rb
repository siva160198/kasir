class AddDiscountToSaleItems < ActiveRecord::Migration[8.1]
  def change
    add_column :sale_items, :discount, :bigint, null: false, default: 0
  end
end
