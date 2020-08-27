class Spree::Core::Importer::Mirakl::Order < Spree::Core::Importer::Order
  class << self

    def import(user, params)
      begin
        ensure_country_id_from_params params[:ship_address_attributes]
        ensure_state_id_from_params params[:ship_address_attributes]
        ensure_country_id_from_params params[:bill_address_attributes]
        ensure_state_id_from_params params[:bill_address_attributes]

        create_params = params.slice :currency
        order = Spree::Order.create! create_params

        order.associate_user!(user)

        shipments_attrs = params.delete(:shipments_attributes)

        create_line_items_from_params(params.delete(:line_items_attributes), order)
        create_adjustments_from_params(params.delete(:adjustments_attributes), order)

        if completed_at = params.delete(:completed_at)
          order.completed_at = completed_at
          order.state = 'complete'
        end

        params.delete(:user_id) unless user.try(:has_spree_role?, "admin") && params.key?(:user_id)

        payment_attributes = params.delete(:payments_attributes)
        order.update_attributes!(params)

        create_shipments_from_params(shipments_attrs, order)
        create_payments_from_params(payment_attributes, order)

        # Really ensure that the order totals & states are correct
        order.updater.update
        if shipments_attrs.present?
          order.shipments.each_with_index do |shipment, index|
            shipment.update_columns(cost: shipments_attrs[index][:cost].to_f) if shipments_attrs[index][:cost].present?
          end
        end
        order.reload
      rescue Exception => e
        order.destroy if order && order.persisted?
        raise e.message
      end
    end
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
          shipment.refresh_rates(Spree::ShippingMethod::DISPLAY_ON_FRONT_AND_BACK_END)
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
