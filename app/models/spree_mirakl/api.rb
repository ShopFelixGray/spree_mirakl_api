class SpreeMirakl::Api
  attr_reader :response, :store

  def initialize(store)
    @store = store
    @response = nil
  end

  def tracking(mirakl_order_id, shipping_method, tracking_url)
    @response = SpreeMirakl::Request.new(@store).put("/api/orders/#{mirakl_order_id}/tracking?shop_id=#{@store.shop_id}",({  'carrier_name': shipping_method.try(:name), 'carrier_url': tracking_url }).to_json)
  end

  def ship(mirakl_order_id)
    @response = SpreeMirakl::Request.new(@store).put("/api/orders/#{mirakl_order_id}/ship?shop_id=#{@store.shop_id}", '')
  end

  def account
    @response = SpreeMirakl::Request.new(@store).get("/api/account")
  end

  def refund_reasons
    @response = SpreeMirakl::Request.new(@store).get("/api/reasons/REFUND?shop_id=#{@store.shop_id}")
  end

  def get_order(mirakl_order_id)
    @response = SpreeMirakl::Request.new(@store).get("/api/orders?order_ids=#{mirakl_order_id}&shop_id=#{@store.shop_id}")
  end

  def shipping_orders
    @response = SpreeMirakl::Request.new(@store).get("/api/orders?order_state_codes=SHIPPING&shop_id=#{@store.shop_id}")
  end

  def waiting_acceptance
    @response = SpreeMirakl::Request.new(@store).get("/api/orders?order_state_codes=WAITING_ACCEPTANCE&shop_id=#{@store.shop_id}")
  end

  def accept_order(mirakl_order_id, json_data)
    @response = SpreeMirakl::Request.new(@store).put("/api/orders/#{mirakl_order_id}/accept?shop_id=#{@store.shop_id}", ({ 'order_lines': json_data }).to_json)
  end

  def refund(return_json)
    @response = SpreeMirakl::Request.new(@store).put("/api/orders/refund?shop_id=#{@store.shop_id}", ({ 'refunds': return_json }).to_json)
  end

end