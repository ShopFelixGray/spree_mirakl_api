class Spree::Core::Importer::Mirakl::Order < Spree::Core::Importer::Order
  class << self
    # Override default create_payments because order requires response_code for Mirakl Orders
    def create_payments_from_params(payments_hash, order)
      return [] unless payments_hash
      payments_hash.each do |p|
        begin
          payment = order.payments.build order: order
          payment.amount = p[:amount].to_f
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
      return [] unless shipments_hash

      inventory_units = Spree::Stock::InventoryUnitBuilder.new(order).units

      shipments_hash.each do |s|
        begin
          shipment = order.shipments.build
          shipment.tracking       = s[:tracking]
          shipment.stock_location = Spree::StockLocation.find_by_admin_name(s[:stock_location]) || Spree::StockLocation.find_by_name!(s[:stock_location])

          shipment_units = s[:inventory_units] || []
          shipment_units.each do |su|
            ensure_variant_id_from_params(su)

            inventory_unit = inventory_units.detect { |iu| iu.variant_id.to_i == su[:variant_id].to_i }

            if inventory_unit.present?
              inventory_unit.shipment = shipment

              if s[:shipped_at].present?
                inventory_unit.pending = false
                inventory_unit.state = 'shipped'
              end

              inventory_unit.save!

              # Don't assign shipments to this inventory unit more than once
              inventory_units.delete(inventory_unit)
            end
          end

          if s[:shipped_at].present?
            shipment.shipped_at = s[:shipped_at]
            shipment.state      = 'shipped'
          end

          shipment.save!

          shipping_method = Spree::ShippingMethod.find_by_name(s[:shipping_method]) || Spree::ShippingMethod.find_by_admin_name!(s[:shipping_method])
          rate = shipment.shipping_rates.create!(shipping_method: shipping_method, cost: s[:cost])

          shipment.selected_shipping_rate_id = rate.id
          shipment.update_amounts

          adjustments = s.delete(:adjustments_attributes)
          create_adjustments_from_params(adjustments, order, shipment)
        rescue Exception => e
          raise "Order import shipments: #{e.message} #{s}"
        end
      end
    end

  end
end
