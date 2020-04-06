class AddKlarnaTransactionToOrders < ActiveRecord::Migration[4.2]

  def change
    add_column :spree_orders, :klarna_transaction, :string
  end

end
