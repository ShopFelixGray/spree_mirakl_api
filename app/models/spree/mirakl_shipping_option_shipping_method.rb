module Spree
  class MiraklShippingOptionShippingMethod < ActiveRecord::Base
    belongs_to :mirakl_shipping_option
    belongs_to :shipping_method
  end
end

