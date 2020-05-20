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
      transaction = Spree::MiraklTransaction.find_by(mirakl_order_id: mirakl_source)
  
      request = SpreeMirakl::Api.new(transaction.mirakl_store).cancel(transaction.mirakl_order_id)
      # We have to do it this way because if it is a success parsed response will have refunds
      # if it fails we get message
      if request.success?
        ActiveMerchant::Billing::Response.new(true, "", {}, {})
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