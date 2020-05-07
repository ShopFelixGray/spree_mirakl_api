class Spree::MiraklOrderLine < ActiveRecord::Base
  # This class repersents an order line in mirakl. We use it to store the order line id and associated taxes
  belongs_to :line_item

  has_many :mirakl_order_line_taxes
end