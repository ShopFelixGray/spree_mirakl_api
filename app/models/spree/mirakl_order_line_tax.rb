class Spree::MiraklOrderLineTax < ActiveRecord::Base
  belongs_to :mirakl_order_line

  scope :taxes, -> { where(tax_type: 'tax') }
  scope :shipping_taxes, -> { where(tax_type: 'shipping_tax') }
end