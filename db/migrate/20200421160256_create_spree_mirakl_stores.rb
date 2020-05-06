class CreateSpreeMiraklStores < ActiveRecord::Migration
  def change
    create_table :spree_mirakl_stores do |t|
      t.string :name
      t.string :api_key
      t.boolean :active, default: true
      t.text :url
      t.integer :shop_id
      t.references :user, index: true
      t.timestamps null: false
    end
  end
end