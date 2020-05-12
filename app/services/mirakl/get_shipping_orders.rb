module Mirakl
  class GetShippingOrders < ApplicationService

    attr_reader :stores

    def initialize(args = {})
      super
      @stores = args[:stores]
    end

    def call
      begin
        @stores.each do |store|
          orders = get_ready_orders(store)
          build_orders(orders, store)
        end
      rescue ServiceError => error
        add_to_errors(error.messages)
      end

      return completed_without_errors?
    end

    def get_ready_orders(store)
      request = SpreeMirakl::Api.new(store).get_order_state("SHIPPING")
      if request.success?
        begin
          return JSON.parse(request.body, {symbolize_names: true})[:orders]
        rescue
          raise ServiceError.new(["Error in getting Waiting Acceptance"])
        end
      else
        raise ServiceError.new(["Error in getting Waiting Acceptance"])
      end
    end


    def build_orders(orders, store)
      orders.each do |order|
        service = Mirakl::BuildOrder.new({mirakl_order_id: order[:order_id], store: store})
        unless service.call
          raise ServiceError.new(["Error processing order: #{order[:order_id]}", service.errors])
        end
      end
    end

  end
end