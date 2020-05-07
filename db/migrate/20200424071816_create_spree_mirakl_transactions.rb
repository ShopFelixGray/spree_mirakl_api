class CreateSpreeMiraklTransactions < ActiveRecord::Migration
  def change
    create_table :spree_mirakl_transactions do |t|
      t.string :mirakl_order_id
      t.references :mirakl_store, index: true
      t.references :order, index: true

      t.timestamps null: false
    end
  end
end