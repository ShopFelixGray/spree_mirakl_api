Spree::Shipment.class_eval do
  
  self.state_machine.after_transition(
    to: :shipped,
    do: :update_mirakl
  )

  def update_mirakl
    if order.channel == 'mirakl'
      store = order.mirakl_transaction.mirakl_store
      order_id = order.mirakl_transaction.mirakl_order_id
      MiraklShipJob.perform_later store, order_id, shipping_method, tracking_url
    end
  end
end