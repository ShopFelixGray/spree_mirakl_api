module Spree
  class Gateway::Mirakl < Gateway

    preference :default_stock_location, :integer, default: 1

    def provider_class
      ActiveMerchant::Billing::Mirakl
    end

    def payment_source_class
      MiraklTransaction
    end

    def source_required?
      true
    end

    def method_type
      'mirakl'
    end

    def self.version
      "1.0"
    end
  end
end