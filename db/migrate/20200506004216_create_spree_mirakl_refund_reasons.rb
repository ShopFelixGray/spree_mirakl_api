class CreateSpreeMiraklRefundReasons < ActiveRecord::Migration
  def change
    create_table :spree_mirakl_refund_reasons do |t|
      t.string :code
      t.string :label
      t.references :mirakl_store, index: true
      t.timestamps null: false
    end
  end
end