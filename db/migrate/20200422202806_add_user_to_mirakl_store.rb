class AddUserToMiraklStore < ActiveRecord::Migration
  def change
    add_reference :spree_mirakl_stores, :user, null: false

    add_index :spree_mirakl_stores, :user_id
  end
end