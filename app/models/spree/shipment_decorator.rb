Spree::Shipment.class_eval do

  self.state_machine.after_transition(
    to: :shipped,
    do: :update_mirakl
  )

  def update_mirakl
    return unless order.channel == 'mirakl'

    store = order.mirakl_transaction.mirakl_store
    order_id = order.mirakl_transaction.mirakl_order_id
    MiraklShipJob.perform_later store.id, order_id, self.id
  end

  def mirakl_tracking_url
    self.tracking_url
  end

  def shipping_carrier_name
    shipping_method.name.split(' ').try(:first)
  end
end
