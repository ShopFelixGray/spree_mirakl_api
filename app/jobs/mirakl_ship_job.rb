class MiraklShipJob < ActiveJob::Base
  queue_as :default

  def perform(store, order_id, shipping_method, tracking_url)
    mirakl_request = SpreeMirakl::Api.new(store)
    request = mirakl_request.tracking(order_id, shipping_method, tracking_url)
    ship_request = mirakl_request.ship(order_id)
    unless request.success? && ship_request.success?
      raise Exception.new('Issue with pushing tracking info to Mirakl. Confirm in Mirakl tracking info exist and item is shipped')
    end
  end
end
