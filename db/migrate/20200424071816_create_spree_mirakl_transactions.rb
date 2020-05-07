class CreateSpreeMiraklTransactions < ActiveRecord::Migration
  def change
    create_table :spree_mirakl_transactions do |t|
      t.references :order, index: true
      t.references :return_authorization, index: true

      t.timestamps null: false
    end
  end
end