module Spree
  class Gateway::Mirakl < Gateway

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
    
    def cancel(mirakl_source, options={})
      return_json = []
      # Because spree doesn't use a reason code for cancel we just send the first reason 
      # TODO: Confirm that is okay
      transaction = Spree::MiraklTransaction.find_by(mirakl_order_id: mirakl_source)
      transaction.order.line_items.each do |line_item|
        mirakl_order_line = line_item.mirakl_order_line
        return_json << {  'amount': line_item.amount, 
          'order_line_id': mirakl_order_line.mirakl_order_line_id, 
          'shipping_amount': 0,
          'taxes': taxes_json(mirakl_order_line.mirakl_order_line_taxes.taxes),
          'reason_code': transaction.mirakl_store.mirakl_refund_reasons.first.code,
          'shipping_taxes': taxes_json(mirakl_order_line.mirakl_order_line_taxes.shipping_taxes),
          'quantity': line_item.quantity,
          'currency_iso_code': transaction.order.currency
        }
      end
  
      request = SpreeMirakl::Request.new(transaction.mirakl_store).put("/api/orders/refund?shop_id=#{transaction.mirakl_store.shop_id}", ({ 'refunds': return_json }).to_json)
  
      # We have to do it this way because if it is a success parsed response will have refunds
      # if it fails we get message
      if request.success?
        ActiveMerchant::Billing::Response.new(true, "", request.parsed_response, {})
      else 
        ActiveMerchant::Billing::Response.new(false, request.parsed_response['message'][0...255], {}, {})
      end
    end

    def taxes_json(taxes)
      json_data = []
      taxes.each do |tax|
        # We divide by quantity causes taxes come over on a per line item basis. If an order has 2 and we return one only half taxes should go back
        json_data << {
          'amount': tax.amount.to_f,
          'code': tax.code
        }
      end
      return json_data
    end

  end
end