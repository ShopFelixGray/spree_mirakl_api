module Mirakl
  class BuildOrder < ApplicationService

    attr_reader :order

    def initialize(args = {})
      super
      @order_id = args[:order_id]
      @store = args[:store]
      @order = nil
    end

    def call
      begin
        # If order already exist we dont want to remake it. We may want to alert admin some how with an email
        order_data = get_order(@order_id, @store)
        unless Spree::MiraklTransaction.find_by(mirakl_order_id: order_data['order_id']).present?
          build_order_for_user(order_data, @store)
        end
      rescue ServiceError => error
        add_to_errors(error.messages)
      end

      return completed_without_errors?
    end

    def get_order(order_id, store)
      headers = { 'Authorization': store.api_key, 'Accept': 'application/json' }
      request = HTTParty.get("#{store.url}/api/orders?order_ids=#{order_id}", headers: headers)
      if request.success?
        return JSON.parse(request.body)['orders'][0]
      else
        raise ServiceError.new(["Issue processing #{order_id}"])
      end
    end

    def build_order_for_user(order_data, store)
      new_order = Spree::Order.create!
      new_order.associate_user!(store.user)
      new_order.channel = 'mirakl'
      new_order = add_line_items(new_order, order_data['order_lines'])
      new_order.billing_address = build_address(order_data['customer']['billing_address'], new_order.user)
      new_order.ship_address = build_address(order_data['customer']['shipping_address'], new_order.user)
      new_order.save
      create_payment(new_order, order_data['total_price'], order_data['order_id'], store)

      while order_next(new_order);end

      if new_order.complete?
        @order = new_order
      else
        @order.destroy
        raise ServiceError.new(["Could not complete order: #{new_order.errors.full_messages.try(:first)}"])
      end
    end

    def add_line_items(order, order_lines)
      order_lines.each do |order_line|
        variant = Spree::Variant.includes(:stock_items).find_by(sku: order_line['offer_sku'])
        line_item_added = order.contents.add(variant, order_line['quantity'])
        mirakl_order_line = Spree::MiraklOrderLine.create!(line_item: line_item_added, mirakl_order_line_id: order_line['order_line_id'])
        build_taxes(order_line, mirakl_order_line)
      end
      return order
    end

    def build_address(address, user)
      country = get_country_for(address['country_iso_code'] || address['country'])
      state = get_state_for(address['state'], country)
      Spree::Address.create!(
        firstname: address['firstname'],
        lastname: address['lastname'],
        address1: address['street_1'],
        address2: address['street_2'],
        city: address['city'],
        zipcode: address['zip_code'],
        phone: address['phone_secondary'],
        state_name: address['state'],
        company: address['company'],
        state: state,
        country: country
      )
    end

    def build_taxes(order_line, mirakl_order_line)
      order_line['taxes'].each do |tax|
        Spree::MiraklOrderLineTax.create!(
          tax_type: 'tax',
          amount: tax['amount'],
          code: tax['code'],
          mirakl_order_line: mirakl_order_line
        )
      end

      order_line['shipping_taxes'].each do |tax|
        Spree::MiraklOrderLineTax.create!(
          tax_type: 'shipping_tax',
          amount: tax['amount'],
          code: tax['code'],
          mirakl_order_line: mirakl_order_line
        )
      end
    end

    def get_country_for(country_iso)
      Spree::Country.find_by(iso: country_iso)
    end

    def get_state_for(state_abbr, country)
      Spree::State.find_by(abbr: state_abbr, country: country)
    end

    def create_payment(order, amount, external_number, store)
      begin
        payment = order.payments.build order: order
        payment.amount = amount
        payment.state =  'completed'
        payment.created_at = Time.current()
        payment.payment_method = Spree::PaymentMethod.find_by_name!("Mirakl")
        payment.response_code = external_number
        payment.source = Spree::MiraklTransaction.create!(order: order, mirakl_order_id: external_number, mirakl_store: store)
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