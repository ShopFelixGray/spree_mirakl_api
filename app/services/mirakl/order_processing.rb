module Mirakl
  class OrderProcessing < ApplicationService

    attr_reader :stores

    def initialize(args = {})
      super
      @stores = args[:stores]
    end

    def call
      begin
        @stores.each do |store|
          orders = get_orders(store)
          process_orders(orders, store)
        end
      rescue ServiceError => error
        add_to_errors(error.messages)
      end

      completed_without_errors?
    end

    def get_orders(store)
      request = SpreeMirakl::Api.new(store).get_order_state("WAITING_ACCEPTANCE,SHIPPING")
      raise ServiceError.new([Spree.t(:error_requesting_waiting_and_shipping)]) unless request.success?
      JSON.parse(request.body, symbolize_names: true)[:orders]
    end

    def process_orders(orders, store)
      orders.each do |order|
        if order[:order_state] == 'WAITING_ACCEPTANCE'
          can_fulfill = true
          order[:order_lines].each do |order_line|
            can_fulfill = check_stock(order_line[:offer_sku], order_line[:quantity])
            break unless can_fulfill
          end
          accept_or_reject_order(order, can_fulfill, store)
        elsif order[:order_state] == 'SHIPPING' # do elsif just to be safe not making double order
          order_service = Mirakl::BuildOrder.new(mirakl_order_id: order[:order_id], store: store)
          raise ServiceError.new([Spree.t(:order_process_error, order_id: order[:order_id]), order_service.errors]) unless order_service.call
        end
      end
    end

    def accept_or_reject_order(order, can_fulfill, store)
      request = SpreeMirakl::Api.new(store).accept_order(order[:order_id], accept_or_reject_order_json(order, can_fulfill))

      if request.success? && can_fulfill
        order_service = Mirakl::BuildOrder.new(mirakl_order_id: order[:order_id], store: store)
        raise ServiceError.new([Spree.t(:order_process_error, order_id: order[:order_id]), order_service.errors]) unless order_service.call
      elsif !request.success?
        raise ServiceError.new([Spree.t(:issue_acceptance, order_id: order[:order_id])])
      end
    end

    def accept_or_reject_order_json(order, can_fulfill)
      order_data = []

      order[:order_lines].each do |order_line|
        order_data << { accepted: can_fulfill, id: order_line[:order_line_id] }
      end
      order_data
    end

    def check_stock(sku, quantity)
      variant = Spree::Variant.find_by(sku: sku)

      variant.present? ? (quantity <= variant.quantity_check) : false
    end

  end
end
