class Spree::MiraklOrderLine < ActiveRecord::Base
  # This is Mirakls version of a line
  belongs_to :line_item

  has_many :mirakl_order_line_taxes
end