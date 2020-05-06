class AddUrlToMiraklStore < ActiveRecord::Migration
  def change
    add_column :spree_mirakl_stores, :url, :text
  end
end