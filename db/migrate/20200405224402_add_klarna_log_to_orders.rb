class AddKlarnaLogToOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :spree_orders, :klarna_log, :string
  end
end
