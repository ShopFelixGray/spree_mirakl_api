class MiraklInventoryUpdateJob < ActiveJob::Base
  queue_as :default

  def perform(store_id)
    store = Spree::MiraklStore.find(store_id)
    service = Mirakl::UpdateInventory.new(store: store)
    raise Exception.new(Spree.t(:sync_inventory_fail, shop_id: store.shop_id)) unless service.call
  end
end
