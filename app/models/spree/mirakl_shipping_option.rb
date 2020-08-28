module Spree
  class MiraklShippingOption < ActiveRecord::Base
    belongs_to :mirakl_store

    has_many :mirakl_shipping_option_shipping_methods, dependent: :destroy
    has_many :shipping_methods, through: :mirakl_shipping_option_shipping_methods
  end
end

