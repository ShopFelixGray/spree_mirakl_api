Spree::InventoryUnit.class_eval do
  has_one :mirakl_order_line_inventory_unit
  has_one :mirakl_order_line, through: :mirakl_order_line_inventory_unit
end