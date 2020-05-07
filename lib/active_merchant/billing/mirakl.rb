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

      def cancel(mirakl_source, options={})
        ActiveMerchant::Billing::Response.new(true, "", {}, {})
      end

      def void(mirakl_source, options = {})
        ActiveMerchant::Billing::Response.new(true, "", {}, {})
      end

      def refund(money, mirakl_source, options = {})
        ActiveMerchant::Billing::Response.new(true, "", {}, {})
      end

      def credit(money, mirakl_source, options = {})
        refund = options[:originator]
        return_json = []
        return ActiveMerchant::Billing::Response.new(false, "Reimburstment Required", {}, {}) unless refund.reimbursement.present?
        refund.reimbursement.customer_return.return_items.each do |return_item|
          line_item = return_item.inventory_unit.line_item
          # TODO FIX REASON CODE
          return_json << {  'amount': return_item.amount, 
                            'order_line_id': line_item.mirakl_order_line.mirakl_order_line_id, 
                            'shipping_amount': 0, 
                            'reason_code': "15",
                            'taxes': taxes_json(line_item.mirakl_order_line.mirakl_order_line_taxes.taxes, line_item.quantity),
                            'shipping_taxes': taxes_json(line_item.mirakl_order_line.mirakl_order_line_taxes.shipping_taxes, line_item.quantity),
                            'quantity': 1,
                            'currency_iso_code': 'USD'
                          }
        end
        # NOTE WE NEED SHOP ID NEED TO LOOK INTO WHERE THAT IS
        headers = { 'Authorization': Spree::MiraklStore.first.api_key, 'Accept': 'application/json', 'Content-Type': 'application/json' }
        request = HTTParty.put("#{Spree::MiraklStore.first.url}/api/orders/refund", body: ({ 'refunds': return_json }).to_json, headers: headers)

        # We have to do it this way because if it is a success parsed response will have refunds
        # if it fails we get message
        if request.success?
          ActiveMerchant::Billing::Response.new(true, "", request.parsed_response, authorization: request.parsed_response["refunds"].map{ |refund| refund["refund_id"] }.join('-'))
        else 
          ActiveMerchant::Billing::Response.new(false, request.parsed_response['message'][0...255], {}, {})
        end
      end

      def commit(method, url, parameters=nil, options = {}, ret_charge=false)
        ActiveMerchant::Billing::Response.new(true, "", {}, {})
      end

      def taxes_json(taxes, quantity)
        json_data = []
        taxes.each do |tax|
          # We divide by quantity causes taxes come over on a per line item basis. If an order has 2 and we return one only half taxes should go back
          json_data << {
            'amount': tax.amount/quantity,
            'code': tax.code
          }
        end
        return json_data
      end
    end
  end
end