class Spree::MiraklOrderLineInventoryUnit < ActiveRecord::Base
  belongs_to :inventory_unit
  belongs_to :mirakl_order_line
end
