class AddShippingOptionFilterToMiraklStore < ActiveRecord::Migration
  def change
    add_column :spree_mirakl_stores, :shipping_method_display_rate, :string, default: 'both'
  end
end
