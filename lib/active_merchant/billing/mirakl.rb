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

      def refund(money, mirakl_source, options = {})
        credit(money, mirakl_source, options = {})
      end

      def credit(money, mirakl_source, options = {})
        refund = options[:originator]
        return_json = []
        transaction = Spree::MiraklTransaction.find_by(mirakl_order_id: mirakl_source)
        
        request = SpreeMirakl::Api.new(transaction.mirakl_store).get_order(transaction.mirakl_order_id)
        order_data = nil
        if request.success?
          order_data = JSON.parse(request.body, {symbolize_names: true})[:orders][0]
        else
          return ActiveMerchant::Billing::Response.new(false, "Could not get data from Mirakl for order: #{transaction.mirakl_order_id}", {}, {})
        end

        refunds_processed =  {}
        refund.reimbursement.customer_return.return_items.each do |return_item|
          line_item_quantity = return_item.inventory_unit.line_item.quantity
          inventory_unit_sku = return_item.inventory_unit.variant.sku
          order_line_data = nil
          order_data[:order_lines].each do |order_line|
            if order_line[:offer_sku] == inventory_unit_sku
              if (order_line[:refunds].length + (refunds_processed[order_line[:order_line_id]] || 0)) < line_item_quantity
                order_line_data = order_line
                refunds_processed[order_line[:order_line_id]] = (refunds_processed[order_line[:order_line_id]] || 0) + 1
                break
              end
            end
          end

          unless order_line_data.present?
            return ActiveMerchant::Billing::Response.new(false, "No Refund Possible for SKU: #{inventory_unit_sku}", {}, {})
          end
          # mirakl_order_line = return_item.inventory_unit.line_item.mirakl_order_line
          # Look to refactor refund reasons code
          return_json << {  'amount': return_item.total, 
                            'order_line_id': order_line_data[:order_line_id], 
                            'shipping_amount': order_line_data[:shipping_price]/return_item.inventory_unit.line_item.order.item_count,
                            'reason_code': transaction.mirakl_store.mirakl_refund_reasons.joins(:refund_reasons).where(spree_refund_reasons: { id: refund.refund_reason_id }).first.try(:code) || transaction.mirakl_store.mirakl_refund_reasons.first.code,
                            'taxes': taxes_json(order_line_data[:taxes], line_item_quantity),
                            'shipping_taxes': taxes_json(order_line_data[:shipping_taxes], line_item_quantity),
                            'quantity': 1,
                            'currency_iso_code': transaction.order.currency
                          }
        end

        request = SpreeMirakl::Api.new(transaction.mirakl_store).refund(return_json)
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
            'amount': tax[:amount].to_f/quantity,
            'code': tax[:code]
          }
        end
        return json_data
      end
    end
  end
end