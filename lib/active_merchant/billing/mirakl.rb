module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class Mirakl < Gateway
      self.supported_countries = %w(US)
      self.default_currency = 'USD'
      self.money_format = :dollars

      self.homepage_url = 'https://www.mirakl.com/'
      self.display_name = 'Mirakl'

      def credit_card?
        false
      end

      def authorize(money, mirakl_source, options = {})
        ActiveMerchant::Billing::Response.new(true, "", {}, {})
      end

      def purchase(money, mirakl_source, options = {})
        ActiveMerchant::Billing::Response.new(true, "", {}, {})
      end

      def capture(money, mirakl_source, options = {})
        ActiveMerchant::Billing::Response.new(true, "", {}, {})
      end

      def void(mirakl_source, options = {})
        ActiveMerchant::Billing::Response.new(true, "", {}, {})
      end

      def refund(money, mirakl_source, options = {})
        ActiveMerchant::Billing::Response.new(true, "", {}, {})
      end

      def credit(money, mirakl_source, options = {})
        ActiveMerchant::Billing::Response.new(true, "", {}, {})
      end

      def commit(method, url, parameters=nil, options = {}, ret_charge=false)
        ActiveMerchant::Billing::Response.new(true, "", {}, {})
      end
    end
  end
end