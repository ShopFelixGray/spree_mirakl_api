class Spree::Core::Importer::Mirakl::Order < Spree::Core::Importer::Order
  class << self
    # Override default create_payments because order requires response_code for Mirakl Orders
    def create_payments_from_params(payments_hash, order)
      return [] unless payments_hash
      payments_hash.each do |p|
        begin
          payment = order.payments.build order: order
          payment.amount = p[:amount].to_f + order.shipments.sum(:cost)
          # Order API should be using state as that's the normal payment field.
          # spree_wombat serializes payment state as status so imported orders should fall back to status field.
          payment.state = p[:state] || p[:status] || 'completed'
          payment.created_at = p[:created_at] if p[:created_at]
          payment.payment_method = Spree::PaymentMethod.find_by_name!(p[:payment_method])
          payment.source = create_source_payment_from_params(p[:source], payment) if p[:source]
          payment.response_code = p[:response_code]
          payment.save!
        rescue Exception => e
          raise "Order import payments: #{e.message} #{p}"
        end
      end
    end

    def create_source_payment_from_params(source_hash, payment)
      begin
        Spree::MiraklTransaction.create!(
          order: payment.order,
          mirakl_order_id: source_hash[:mirakl_order_number],
          mirakl_store_id: source_hash[:mirakl_store_id]
         )
      rescue Exception => e
        raise "Order import source payments: #{e.message} #{source_hash}"
      end
    end

    def create_shipments_from_params(shipments_hash, order)
      order.create_proposed_shipments
      shipments_hash.each_with_index do |s, index|
        shipment = order.shipments[index]

        if s[:shipping_method_id]
          selected_rate = shipment.shipping_rates.detect { |rate|
            rate.shipping_method_id == s[:shipping_method_id]
          }
          shipment.selected_shipping_rate_id = selected_rate.id if selected_rate
          shipment.update_amounts
        end
      end
    end
  end
end
