class MiraklShipJob < ActiveJob::Base
  queue_as :default

  def perform(store_id, order_id, shipment_id)
    store = Spree::MiraklStore.find(store_id)
    shipment = Spree::Shipment.find(shipment_id)

    mirakl_request = SpreeMirakl::Api.new(store)
    get_order = mirakl_request.get_order(order_id)
    raise ServiceError.new(["Issue getting #{order_id}"]) unless get_order.success?

    order_data = JSON.parse(get_order.body, symbolize_names: true)[:orders][0]
    shipping_name = shipment.shipping_carrier_name
    carrier = store.mirakl_store_carriers.where(label: shipping_name.downcase).first

    if carrier.present?
      # registered carrier
      shipping_info = { carrier_code: carrier.code, tracking_number: shipment.tracking }
    else
      # Unregistered shipping carrier
      shipping_info = { carrier_name: shipping_name, tracking_number: shipment.tracking, carrier_url: shipment.mirakl_tracking_url }
    end

    request = mirakl_request.tracking(order_id,
                                      shipping_info.to_json)

    # Only ship if in shipping state
    if order_data[:order_state] == 'SHIPPING'
      ship_request = mirakl_request.ship(order_id)
      raise Exception.new(Spree.t(:shipping_fail)) unless ship_request.success?
    end

    raise Exception.new(Spree.t(:shipping_fail)) unless request.success?
  end
end
