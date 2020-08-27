class CreateMiraklShippingOptionShippingMethods < ActiveRecord::Migration
  def change
    create_table :spree_mirakl_shipping_option_shipping_methods do |t|
      t.references :mirakl_shipping_option, index: { name: :mirakl_shipping_option_auth }
      t.references :shipping_method, index: { name: :shipping_method_mirakl_shipping }
      t.timestamps null: false
    end
  end
end
