class CreateSpreeMiraklOrderLines < ActiveRecord::Migration
  def change
    create_table :spree_mirakl_order_lines do |t|
      t.string :mirakl_order_line_id
      t.references :line_item, null: false
      t.timestamps null: false
    end
  end
end