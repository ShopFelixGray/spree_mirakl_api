module Mirakl
  class BuildOrder < ApplicationService
    attr_reader :order

    def initialize(args = {})
      super
      @mirakl_order_id = args[:mirakl_order_id]
      @store = args[:store]
      @force_sync = args[:force_sync] || false
      @order_total = 0
      @order = nil
    end

    def call
      begin
        # If order already exist we dont want to remake it. We may want to alert admin some how with an email
        unless Spree::MiraklTransaction.find_by(mirakl_order_id: @mirakl_order_id).present?
          order_data = get_order(@mirakl_order_id, @store)
          puts order_data
          if order_data[:order_state] == 'SHIPPING' || @force_sync
            build_order_for_user(order_data, @store)
          end
        end
      rescue ServiceError => error
        add_to_errors(error.messages)
      end

      completed_without_errors?
    end

    def get_order(mirakl_order_id, store)
      request = SpreeMirakl::Api.new(store).get_order(mirakl_order_id)
      raise ServiceError.new(["Issue processing #{mirakl_order_id}"]) unless request.success?
      JSON.parse(request.body, symbolize_names: true)[:orders][0]
    end

    def get_order_hash(order_information, store)
      # Source has to come after order is created
      {
        email: store.user.email,
        channel: 'mirakl',
        line_items_attributes: line_items_hash(order_information[:order_lines]),
        completed_at: Time.current,
        payments_attributes: [
          {
            amount: @order_total,
            payment_method: 'Mirakl',
            created_at: Time.current,
            response_code: order_information[:order_id],
            source: { mirakl_order_number: order_information[:order_id], mirakl_store_id: store.id }
          }
        ],
        bill_address_attributes: build_address(order_information[:customer][:billing_address], store.user),
        ship_address_attributes: build_address(order_information[:customer][:shipping_address], store.user)
      }
    end

    def line_items_hash(order_lines)
      line_items = []
      order_lines.each do |order_line|
        offer_sku = order_line[:offer_sku]
        quantity = order_line[:quantity]

        variant = Spree::Variant.includes(:stock_items).active.find_by(sku: offer_sku)
        raise ServiceError.new(["Issue finding #{offer_sku}"]) unless variant.present?

        @order_total += (variant.price * quantity)
        line_items << { sku: variant.sku, quantity: quantity, price: variant.price }
      end
      line_items
    end

    def build_order_for_user(order_data, store)
      @order = Spree::Core::Importer::Mirakl::Order.import(store.user, get_order_hash(order_data, store))
    end

    def build_address(address, user)
      SpreeMirakl::Address.new(address, user).build_address
    end

  end
end
