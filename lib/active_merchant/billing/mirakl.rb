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

      def refund(money, response_code, options = {})
        credit(money, response_code, options)
      end

      def credit(money, response_code, options = {})
        refund = options[:originator]
        return_json = []
        transaction = Spree::MiraklTransaction.find_by(mirakl_order_id: response_code)

        request = SpreeMirakl::Api.new(transaction.mirakl_store).get_order(transaction.mirakl_order_id)

        return ActiveMerchant::Billing::Response.new(false, "Could not get data from Mirakl for order: #{transaction.mirakl_order_id}", {}, {}) unless request.success?

        order_data = JSON.parse(request.body, {symbolize_names: true})[:orders][0]

        refunds_processed =  {}
        refund.reimbursement.customer_return.return_items.each do |return_item|
          line_item_quantity = return_item.inventory_unit.line_item.quantity
          inventory_unit_sku = return_item.inventory_unit.variant.sku
          order_line_data = nil
          order_data[:order_lines].each do |order_line|
            # See if the sku for the order line matches the return item
            if order_line[:offer_sku].downcase == inventory_unit_sku.downcase
              # If it does then we check if this line item already has returns on it
              # Because we do returns by unit the refunds array should repersent inventory unit
              # Because we maybe returning multiple units on the same line item we want to make sure we keep an accruate account
              # as we go through the loop. That is where refunds_processed[order_line[:order_line_id] is used.
              # If the order is 12 different order_lines with the same skus each one would be incremented to 1
              # and the order_line[:quantity] would be 1. So after one time through  order_line[:quantity] is 1 and refunds_processed[order_line[:order_line_id]] would equal 1
              # so it wouldnt set order_line_data. It would move to the next order_line to see if we can place the refund there
              # If the order has 1 order line with quantity 3 say 1 of a certain sku is already refunded
              # order_line[:refunds].length would equal 1 and then after the first time through refunds_processed[order_line[:order_line_id]] would be 1
              # when the thrid item comes through it should still enter the loop as it be 1 + 1 < 3
              if (order_line[:refunds].length + (refunds_processed[order_line[:order_line_id]] || 0)) < order_line[:quantity]
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
          return_json << {  amount: return_item.total,
                            order_line_id: order_line_data[:order_line_id],
                            shipping_amount: order_line_data[:shipping_price]/return_item.inventory_unit.line_item.order.item_count,
                            reason_code: transaction.mirakl_store.mirakl_refund_reasons.joins(:return_authorization_reasons).where(spree_return_authorization_reasons: { id: return_item.return_authorization.return_authorization_reason_id }).first.try(:code) || transaction.mirakl_store.mirakl_refund_reasons.first.code,
                            taxes: taxes_json(order_line_data[:taxes], line_item_quantity),
                            shipping_taxes: taxes_json(order_line_data[:shipping_taxes], line_item_quantity),
                            quantity: 1,
                            currency_iso_code: transaction.order.currency
                          }
        end
        return_json_uniq = combine_order_lines(return_json)
        request = SpreeMirakl::Api.new(transaction.mirakl_store).refund(return_json_uniq)
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
            amount: tax[:amount].to_f/quantity,
            code: tax[:code]
          }
        end
        json_data
      end

      def combine_order_lines(return_json)
        combined_json = []
        return_json.each do |refund_json|
          found_match = false
          combined_json.each do |new_refund|
            if new_refund[:order_line_id] == refund_json[:order_line_id]
              new_refund_hash = combine_hashes(new_refund, refund_json)
              index = combined_json.index {|hash| hash[:order_line_id] == new_refund[:order_line_id] }
              combined_json[index] = new_refund_hash
              found_match = true
            end
          end

          combined_json << refund_json unless found_match
        end
        combined_json
      end

      def combine_hashes(base_refund, added_refund)
        {
          amount: base_refund[:amount].to_f + added_refund[:amount].to_f,
          order_line_id: base_refund[:order_line_id],
          shipping_amount: base_refund[:shipping_amount].to_f + added_refund[:shipping_amount].to_f,
          reason_code:  base_refund[:reason_code],
          taxes: tax_combine(base_refund[:taxes], added_refund[:taxes]),
          shipping_taxes: tax_combine(base_refund[:shipping_taxes], added_refund[:shipping_taxes]),
          quantity: base_refund[:quantity] + 1,
          currency_iso_code: base_refund[:currency_iso_code]
        }
      end

      def tax_combine(base_taxes, added_taxes)
        new_taxes = []
        # Because these taxes are from the same order line we can assume they will have the same codes
        base_taxes.each do |base_tax|
          added_taxes.each do |added_tax|
            if base_tax[:code] == added_tax[:code]
              new_taxes << {
                amount: base_tax[:amount].to_f + added_tax[:amount].to_f,
                code: base_tax[:code]
              }
            end
          end
        end
        new_taxes
      end

    end
  end
end