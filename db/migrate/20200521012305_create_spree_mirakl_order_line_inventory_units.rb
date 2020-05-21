class CreateSpreeMiraklOrderLineInventoryUnits < ActiveRecord::Migration
  def change
    create_table :spree_mirakl_order_line_inventory_units do |t|
      t.references :mirakl_order_line, null: false
      t.references :inventory_unit, null: false
      t.timestamps null: false
    end
  end
end
