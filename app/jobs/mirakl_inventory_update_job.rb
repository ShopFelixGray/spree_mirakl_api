class MiraklInventoryUpdateJob < ActiveJob::Base
  queue_as :default

  def perform(store_id)
    store = Spree::MiraklStore.find(store_id)
    service = Mirakl::UpdateInventory.new({store: store})
    unless service.call
      raise Exception.new("Issue with updating inventory for store: #{store.shop_id}")
    end
  end
end
