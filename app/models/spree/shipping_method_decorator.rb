Spree::ShippingMethod.class_eval do
  has_many :mirakl_shipping_option_shipping_methods, dependent: :destroy
  has_many :mirakl_shipping_options, through: :mirakl_shipping_option_shipping_methods
end
