module Spree
  class Gateway::Mirakl < Gateway

    preference :default_stock_location, :integer, default: 1
    preference :easypost_carrier_accounts_shipping, :string, default: ''
    preference :UPS_bill_third_party_account, :string, default: ''
    preference :UPS_bill_third_party_country, :string, default: ''
    preference :UPS_bill_third_party_postal_code, :string, default: ''

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

    def cancel(mirakl_store)
      ActiveMerchant::Billing::Response.new(true, "", {}, {})
    end
  end
end