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
      request = SpreeMirakl::Api.new(store).get_order_state("WAITING_ACCEPTANCE,SHIPPING")
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

    def process_orders(orders, store)
      orders.each do |order|
        if order[:order_state] == "WAITING_ACCEPTANCE"
          can_fulfill = true
          order[:order_lines].each do |order_line|
            can_fulfill = check_stock(sku: order_line[:offer_sku], quantity: order_line[:quantity])
            break unless can_fulfill
          end
          accept_or_reject_order(order, can_fulfill, store)
        elsif order[:order_state] == "SHIPPING" # do elsif just to be safe not making double order
          order_service = Mirakl::BuildOrder.new({mirakl_order_id: order[:order_id], store: store})
          unless order_service.call
            raise ServiceError.new(["Error processing order: #{order[:order_id]}", order_service.errors])
          end
        end
      end
    end

    def accept_or_reject_order(order, can_fulfill, store)
      request = SpreeMirakl::Api.new(store).accept_order(order[:order_id], accept_or_reject_order_json(order, can_fulfill))

      if request.success?
        order_service = Mirakl::BuildOrder.new({mirakl_order_id: order[:order_id], store: store})
        unless order_service.call
          raise ServiceError.new(["Error processing order: #{order[:order_id]}", order_service.errors])
        end
      else
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


    def check_stock(sku, quantity)
      variant = Spree::Variant.find_by(sku: sku)

      if variant.present?
        return (quantity <= variant.quantity_check)
      else
        return false
      end
    end

  end
end