class MiraklShipJob < ActiveJob::Base
  queue_as :default

  def perform(store_id, order_id, shipment_id)
    store = Spree::MiraklStore.find(store_id)
    shipment = Spree::Shipment.find(shipment_id)
    mirakl_request = SpreeMirakl::Api.new(store)
    request = mirakl_request.tracking(order_id, shipping_method.shipping_method, tracking_url)
    ship_request = mirakl_request.ship(order_id)
    unless request.success? && ship_request.success?
      raise Exception.new('Issue with pushing tracking info to Mirakl. Confirm in Mirakl tracking info exist and item is shipped')
    end
  end
end
