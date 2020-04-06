class MoveKlarnaDataToPayments < ActiveRecord::Migration[4.2]
  def change
    remove_column :spree_orders, :klarna_hash
	  remove_column :spree_orders, :klarna_transaction
    remove_column :spree_orders, :klarna_log

    add_column :spree_payments, :klarna_hash, :string
    add_column :spree_payments, :klarna_transaction, :string
    add_column :spree_payments, :klarna_log, :text
  end
end
