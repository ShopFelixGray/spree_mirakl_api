class CreateSpreeMiraklStoreCarriers < ActiveRecord::Migration
  def change
    create_table :spree_mirakl_store_carriers do |t|
      t.string :label
      t.string :code
      t.references :mirakl_store, index: true
      t.timestamps null: false
    end
  end
end
