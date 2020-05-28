module Mirakl
  class BuildOrder < ApplicationService
    attr_reader :order

    def initialize(args = {})
      super
      @mirakl_order_id = args[:mirakl_order_id]
      @store = args[:store]
      @force_sync = args[:force_sync] || false
      @order = nil
    end

    def call
      begin
        # If order already exist we dont want to remake it. We may want to alert admin some how with an email
        unless Spree::MiraklTransaction.find_by(mirakl_order_id: @mirakl_order_id).present?
          order_data = get_order(@mirakl_order_id, @store)
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

    def build_order_for_user(order_data, store)
      ActiveRecord::Base.transaction do
        new_order = Spree::Order.create!
        new_order.associate_user!(store.user)
        new_order.channel = 'mirakl'
        new_order = add_line_items(new_order, order_data[:order_lines])
        new_order.billing_address = build_address(order_data[:customer][:billing_address], new_order.user)
        new_order.ship_address = build_address(order_data[:customer][:shipping_address], new_order.user)

        while order_next(new_order)
          if new_order.state == 'payment'
            create_payment(new_order, new_order.total, order_data[:order_id], store)
          end
        end

        @order = new_order
        unless new_order.complete?
          raise ServiceError.new([Spree.t(:could_not_complete_order, message: new_order.errors.full_messages)])
        end
      end
    end

    def add_line_items(order, order_lines)
      order_lines.each do |order_line|
        variant = Spree::Variant.includes(:stock_items).find_by(sku: order_line[:offer_sku])
        order.contents.add(variant, order_line[:quantity])
      end
      order
    end

    def build_address(address, user)
      SpreeMirakl::Address.new(address, user).build_address
    end

    def create_payment(order, amount, mirakl_order_number, store)
      payment = order.payments.build order: order
      payment.amount = amount
      payment.state =  'completed'
      payment.created_at = Time.current()
      payment.payment_method = Spree::PaymentMethod.find_by_name!('Mirakl')
      payment.response_code = mirakl_order_number
      payment.source = Spree::MiraklTransaction.create!(order: order,
                                                        mirakl_order_id: mirakl_order_number,
                                                        mirakl_store: store
                                                       )
      raise ServiceError.new([e.message]) unless payment.save
    end

    def order_next(order)
      order.temporary_address = true
      order.next
    end
  end
end
