module Mirakl
  class StockCheck < ApplicationService

    attr_reader :can_fulfill

    def initialize(args = {})
      super
      @sku = args[:sku]
      @quantity = args[:quantity]
      @can_fulfill = true
    end

    def call
      begin
        check_stock(@sku, @quantity)
      rescue ServiceError => error
        add_to_errors(error.messages)
      end

      return completed_without_errors?
    end

    def check_stock(sku, quantity)
      variant = Spree::Variant.find_by(sku: sku)

      if variant.present?
        @can_fulfill = (quantity <= variant.quantity_check && variant.available?)
      else
        @can_fulfill = false
      end
    end

  end
end