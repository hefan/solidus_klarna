class AddKlarnaHashToOrders < ActiveRecord::Migration[4.2]

  def change
    add_column :spree_orders, :klarna_hash, :string
  end

end
