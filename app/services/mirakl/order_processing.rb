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
          process_orders(orders)
        end
      rescue ServiceError => error
        add_to_errors(error.messages)
      end

      return completed_without_errors?
    end

    def get_orders(store)
      headers = { 'Authorization': store.api_key, 'Accept': 'application/json' }
      request = HTTParty.get("#{store.url}/api/orders?order_state_codes=WAITING_ACCEPTANCE", headers: headers)
      begin
        return JSON.parse(request.body)['orders']
      rescue
        raise ServiceError.new(["Error in getting Waiting Acceptance"])
      end
    end

    def process_orders(orders)
      orders.each do |order|
        can_fulfill = true

        order['order_lines'].each do |order_line|
          service = Mirakl::StockCheck.new({sku: order_line['offer_sku'], quantity: order_line['quantity']})
          service.call
          can_fulfill = service.can_fulfill
          break unless can_fulfill
        end
        accept_or_reject_order(order, can_fulfill)
      end
    end

    def accept_or_reject_order(order, can_fulfill)
      # TODO ACCEPT OR REJECT ORDERS
    end

  end
end