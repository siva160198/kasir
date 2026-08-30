class AddCategoryToCashMovements < ActiveRecord::Migration[8.1]
  def change
    add_column :cash_movements, :category, :string
  end
end
