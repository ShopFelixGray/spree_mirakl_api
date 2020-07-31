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
      '1.0'
    end

    def cancel(response_code, _options = {})
      transaction = Spree::MiraklTransaction.find_by(mirakl_order_id: response_code)

      return ActiveMerchant::Billing::Response.new(false, Spree.t(:mirakl_transaction_not_found), {}, {}) unless transaction.present?

      request = SpreeMirakl::Api.new(transaction.mirakl_store).cancel(transaction.mirakl_order_id)

      success = request.success?
      message = success ? '' : request.parsed_response['message'][0...255]
      # We have to do it this way because if it is a success parsed response will have refunds
      # if it fails we get message
      ActiveMerchant::Billing::Response.new(success, message, {}, {})
    end
  end
end
