module Mirakl
  class UpdateInventory < ApplicationService

    attr_reader :update_json, :store

    def initialize(args = {})
      super
      @store = args[:store]
      @update_json = []
    end

    def call
      begin
        json_data = get_offers()
        update_inventory(json_data)
      rescue ServiceError => error
        add_to_errors(error.messages)
      end

      completed_without_errors?
    end

    def get_offers
      response = SpreeMirakl::Api.new(@store).offers()
      raise ServiceError.new([Spree.t(:issue_requesting_offers, shop_id: @store.shop_id)]) unless response.success?
      JSON.parse(response.body, symbolize_names: true)[:offers]
    end

    def update_inventory(offers_data)
      offers_data.each do |offer|
        # We need to request offer_data cause the index wont include product_tax_code
        response = SpreeMirakl::Api.new(@store).get_offer(offer[:offer_id])
        if response.success?
          offer_data = JSON.parse(response.body, symbolize_names: true)
          variant = Spree::Variant.find_by(sku: offer_data[:shop_sku])
          @update_json << update_inventory_json(variant, offer_data)
          Rails.logger.error Spree.t(:sku_missing, sku: offer_data[:shop_sku]) unless  variant.present?
        else
          Rails.logger.error Spree.t(:sku_missing, sku: offer_data[:shop_sku])
        end
      end

      response = SpreeMirakl::Api.new(@store).update_offers(@update_json)
      raise ServiceError.new([Spree.t(:inventory_update_issue, response: response)]) unless response.success?
    end

    def update_inventory_json(variant, offer_data)
      {
        all_prices: offer_data[:all_prices],
        allow_quote_requests: offer_data[:allow_quote_requests],
        available_ended: offer_data[:available_ended],
        available_started: offer_data[:available_started],
        description: offer_data[:description],
        internal_description: offer_data[:internal_description],
        price: variant.present? ? variant.price : offer_data[:price],
        product_id: offer_data[:product_id],
        product_id_type: offer_data[:product_id_type],
        product_tax_code: offer_data[:product_tax_code],
        quantity: variant.present? ? variant.quantity_check : 0,
        shop_sku: offer_data[:shop_sku],
        state_code: offer_data[:state_code],
        update_delete: 'update'
      }
    end

  end
end
