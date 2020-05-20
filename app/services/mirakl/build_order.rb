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
          if order_data[:order_state] == "SHIPPING" || @force_sync
            build_order_for_user(order_data, @store)
          end
        end
      rescue ServiceError => error
        add_to_errors(error.messages)
      end

      return completed_without_errors?
    end

    def get_order(mirakl_order_id, store)
      request = SpreeMirakl::Api.new(store).get_order(mirakl_order_id)
      if request.success?
        return JSON.parse(request.body, {symbolize_names: true})[:orders][0]
      else
        raise ServiceError.new(["Issue processing #{mirakl_order_id}"])
      end
    end

    def build_order_for_user(order_data, store)
      begin
        ActiveRecord::Base.transaction do
          new_order = Spree::Order.create!
          new_order.associate_user!(store.user)
          new_order.channel = 'mirakl'
          new_order = add_line_items(new_order, order_data[:order_lines])
          new_order.billing_address = build_address(order_data[:customer][:billing_address], new_order.user)
          new_order.ship_address = build_address(order_data[:customer][:shipping_address], new_order.user)
          

          while order_next(new_order)
            if new_order.state == "payment"
              create_payment(new_order, new_order.total, order_data[:order_id], store)
            end
          end

          @order = new_order
          unless new_order.complete?
            raise Exception.new("Could not complete order: #{new_order.errors.full_messages.try(:first)}")
          end
        end
      rescue Exception => e
        raise ServiceError.new(["Could not complete order: #{e.message}"])
      end
    end

    def add_line_items(order, order_lines)
      order_lines.each do |order_line|
        variant = Spree::Variant.includes(:stock_items).find_by(sku: order_line[:offer_sku])
        line_item_added = order.contents.add(variant, order_line[:quantity])
        mirakl_order_line = Spree::MiraklOrderLine.create!(line_item: line_item_added, mirakl_order_line_id: order_line[:order_line_id])
        build_taxes(order_line[:taxes], mirakl_order_line, 'tax')
        build_taxes(order_line[:shipping_taxes], mirakl_order_line, 'shipping_tax')
      end
      return order
    end

    def build_address(address, user)
      SpreeMirakl::Address.new(address, user).build_address
    end

    def build_taxes(order_line_taxes, mirakl_order_line, tax_type)
      order_line_taxes.each do |tax|
        Spree::MiraklOrderLineTax.create!(
          tax_type: tax_type,
          amount: tax[:amount],
          code: tax[:code],
          mirakl_order_line: mirakl_order_line
        )
      end
    end

    def create_payment(order, amount, mirakl_order_number, store)
      begin
        payment = order.payments.build order: order
        payment.amount = amount
        payment.state =  'completed'
        payment.created_at = Time.current()
        payment.payment_method = Spree::PaymentMethod.find_by_name!("Mirakl")
        payment.response_code = mirakl_order_number
        payment.source = Spree::MiraklTransaction.create!(order: order, mirakl_order_id: mirakl_order_number, mirakl_store: store)
        payment.save!
        payment
      rescue Exception => e
        raise ServiceError.new([e.message])
      end
    end

    def order_next(order)
      order.temporary_address = true
      order.next
    end

  end
end