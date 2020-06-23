class MiraklShipJob < ActiveJob::Base
  queue_as :default

  def perform(store_id, order_id, shipment_id)
    store = Spree::MiraklStore.find(store_id)
    shipment = Spree::Shipment.find(shipment_id)
    mirakl_request = SpreeMirakl::Api.new(store)
    get_order = mirakl_request.get_order(order_id)
    raise ServiceError.new(["Issue getting #{order_id}"]) unless get_order.success?
    order_data = JSON.parse(get_order.body, symbolize_names: true)[:orders][0]

    request = mirakl_request.tracking(order_id,
                                      shipment.shipping_method,
                                      shipment.tracking_url)
    # If an order is already marked as shipped dont reship it
    if order_data[:order_state] != 'SHIPPING'
      ship_request = mirakl_request.ship(order_id)
      raise Exception.new(Spree.t(:shipping_fail)) unless ship_request.success?
    end
    raise Exception.new(Spree.t(:shipping_fail)) unless request.success?
  end
end
