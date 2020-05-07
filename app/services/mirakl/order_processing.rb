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

      return completed_without_errors?
    end

    def get_orders(store)
      headers = { 'Authorization': store.api_key, 'Accept': 'application/json' }
      request = HTTParty.get("#{store.url}/api/orders?order_state_codes=WAITING_ACCEPTANCE", headers: headers)
      begin
        return JSON.parse(request.body, {symbolize_names: true})[:orders]
      rescue
        raise ServiceError.new(["Error in getting Waiting Acceptance"])
      end
    end

    def process_orders(orders, store)
      orders.each do |order|
        can_fulfill = true
        order[:order_lines].each do |order_line|
          service = Mirakl::StockCheck.new({sku: order_line[:offer_sku], quantity: order_line[:quantity]})
          if service.call
            can_fulfill = service.can_fulfill
          else
            raise ServiceError.new(service.errors)
          end
          break unless can_fulfill
        end
        accept_or_reject_order(order, can_fulfill, store)
      end
    end

    def accept_or_reject_order(order, can_fulfill, store)
      headers = { 'Authorization': store.api_key, 'Accept': 'application/json', 'Content-Type': 'application/json' }
      request = HTTParty.put("#{store.url}/api/orders/#{order[:order_id]}/accept", 
                  body: ({ 'order_lines': accept_or_reject_order_json(order, can_fulfill) }).to_json, 
                  headers: headers
                )

      unless request.success?
        raise ServiceError.new(["Issue Processing #{order[:order_id]} can fulfill but request issue"])
      end
    end

    def accept_or_reject_order_json(order, can_fulfill)
      order_data = []

      order[:order_lines].each do |order_line|
        order_data << { 'accepted': can_fulfill, 'id': order_line[:order_line_id] }
      end
      order_data
    end

  end
end