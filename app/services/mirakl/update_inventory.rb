module Mirakl
  class UpdateInventory < ApplicationService

    attr_reader :order

    def initialize(args = {})
      super
      @store = args[:store]
    end

    def call
      begin
        json_data = get_offers()
        update_inventory(json_data)
      rescue ServiceError => error
        add_to_errors(error.messages)
      end

      return completed_without_errors?
    end

    def get_offers
      response = SpreeMirakl::Api.new(@store).offers()
      if response.success?
        begin
          return JSON.parse(response.body, {symbolize_names: true})[:offers]
        rescue
          raise ServiceError.new(["Error in getting Mirakl Orders for shop id: #{@store.shop_id}"])
        end
      else
        raise ServiceError.new(["Error in getting Mirakl Orders for shop id: #{@store.shop_id}"])
      end
    end

    def update_inventory(offer_data)
      update_json = []
      offer_data.each do |offer|

      end
    end

  end
end