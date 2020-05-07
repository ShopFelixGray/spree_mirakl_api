Spree::Shipment.class_eval do
  
  self.state_machine.after_transition(
    to: :shipped,
    do: :update_mirakl
  )

  def update_mirakl
    if order.channel == 'mirakl'
      store = order.mirakl_transaction.mirakl_store
      order_id = order.mirakl_transaction.mirakl_order_id
      headers = { 'Authorization': store.api_key, 'Accept': 'application/json', 'Content-Type': 'application/json' }
      request = HTTParty.put("#{store.url}/api/orders/#{order_id}/tracking",
        body: ({  'carrier_name': shipping_method.try(:name), 'carrier_url': tracking_url }).to_json, headers: headers)
      ship_request = HTTParty.put("#{store.url}/api/orders/#{order_id}/ship", headers: headers)
    end
  end
end