class MiraklShipJob < ActiveJob::Base
  queue_as :default

  def perform(store_id, order_id, shipment_id)
    store = Spree::MiraklStore.find(store_id)
    shipment = Spree::Shipment.find(shipment_id)
    mirakl_request = SpreeMirakl::Request.new(store)
    request = mirakl_request.put("/api/orders/#{order_id}/tracking?shop_id=#{store.shop_id}",({  'carrier_name': shipment.shipping_method.try(:name), 'carrier_url': shipment.tracking_url }).to_json)
    ship_request = mirakl_request.put("/api/orders/#{order_id}/ship?shop_id=#{store.shop_id}", '')
    unless request.success? && ship_request.success?
      raise Exception.new('Issue with pushing tracking info to Mirakl. Confirm in Mirakl tracking info exist and item is shipped')
    end
  end
end
