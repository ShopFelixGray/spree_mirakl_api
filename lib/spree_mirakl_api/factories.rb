FactoryGirl.define do
  # Define your Spree extensions Factories within this file to enable applications, and other extensions to use and override them.
  #
  # Example adding this to your spec_helper will load these Factories for use:
  # require 'spree_mirakl_api/factories'
  factory :mirakl_store, class: Spree::MiraklStore do
    name "Test Store"
    api_key "test_key"
    url "https://test.com"
    active true
    shop_id 1
    user  { FactoryGirl.create(:user) }
  end

  factory :product_no_backorder, parent: :product do
    after(:create) do |product|
      product.master.stock_items.each do |a|
        a.update(backorderable: false)
      end
      product.stock_items.each do |a|
        a.update(backorderable: false)
      end
    end
  end

  factory :mirakl_payment_method, class: Spree::Gateway::Mirakl do
    name 'Mirakl'
    active true
    auto_capture true
  end

  factory :mirakl_shipping_options,  class:  Spree::MiraklShippingOption do
    shipping_type_code 'abc'
    shipping_type_label 'abc'
    mirakl_store { FactoryGirl.create(:mirakl_store) }
  end
end
