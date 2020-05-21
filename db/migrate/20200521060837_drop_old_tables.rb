class DropOldTables < ActiveRecord::Migration
  def change
    drop_table :spree_mirakl_order_line_taxes
    drop_table :spree_mirakl_order_lines
  end
end
