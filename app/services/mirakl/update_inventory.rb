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
      raise ServiceError.new(["Error in getting Mirakl Orders for shop id: #{@store.shop_id}"]) unless response.success?
      JSON.parse(response.body, symbolize_names: true)[:offers]
    end

    def update_inventory(offers_data)
      offers_data.each do |offer|
        # We need to request offer_data cause the index wont include product_tax_code
        response = SpreeMirakl::Api.new(@store).get_offer(offer[:offer_id])
        if response.success?
          offer_data = JSON.parse(response.body, symbolize_names: true)
          variant = Spree::Variant.find_by(sku: offer_data[:shop_sku])
          if variant.present?
            @update_json << {
              all_prices: offer_data[:all_prices],
              allow_quote_requests: offer_data[:allow_quote_requests],
              available_ended: offer_data[:available_ended],
              available_started: offer_data[:available_started],
              description: offer_data[:description],
              internal_description: offer_data[:internal_description],
              price: variant.price,
              product_id: offer_data[:product_id],
              product_id_type: offer_data[:product_id_type],
              product_tax_code: offer_data[:product_tax_code],
              quantity: variant.quantity_check,
              shop_sku: offer_data[:shop_sku],
              state_code: offer_data[:state_code],
              update_delete: 'update'
            }
          else
            # Update the item to out of stock because we dont have the SKU and throw an error
            @update_json << {
              all_prices: offer_data[:all_prices],
              allow_quote_requests: offer_data[:allow_quote_requests],
              available_ended: offer_data[:available_ended],
              available_started: offer_data[:available_started],
              description: offer_data[:description],
              internal_description: offer_data[:internal_description],
              price: offer_data[:price],
              product_id: offer_data[:product_id],
              product_id_type: offer_data[:product_id_type],
              product_tax_code: offer_data[:product_tax_code],
              quantity: 0,
              shop_sku: offer_data[:shop_sku],
              state_code: offer_data[:state_code],
              update_delete: 'update'
            }
            Rails.logger.error "Couldn't find variant sku: #{offer_data[:shop_sku]}"
          end
        else
          Rails.logger.error "Couldn't find variant sku: #{offer[:shop_sku]}"
        end
      end

      response = SpreeMirakl::Api.new(@store).update_offers(@update_json)
      raise ServiceError.new(["Issue updating inventory: #{response}"]) unless response.success?
    end

  end
end
