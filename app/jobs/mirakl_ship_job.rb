class MiraklShipJob < ActiveJob::Base
  queue_as :default

  def perform(store_id, order_id, shipment_id)
    store = Spree::MiraklStore.find(store_id)
    shipment = Spree::Shipment.find(shipment_id)
    mirakl_request = SpreeMirakl::Api.new(store)

    request = mirakl_request.tracking(order_id,
                                      shipment.shipping_method,
                                      shipment.tracking_url)
    ship_request = mirakl_request.ship(order_id)
    unless request.success? && ship_request.success?
      raise Exception.new(Spree.t(:shipping_fail))
    end
  end
end
