class CreateMiraklShippingOptions < ActiveRecord::Migration
  def change
    create_table :spree_mirakl_shipping_options do |t|
      t.string :shipping_type_code
      t.string :shipping_type_label
      t.string :shipping_zone_code
      t.string :shipping_zone_label
      t.string :shipping_free_amount
      t.references :mirakl_store, index: true
      t.timestamps null: false
    end
  end
end
