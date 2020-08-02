class SpreeMirakl::Api
  attr_reader :response, :store

  def initialize(store)
    @store = store
    @response = nil
  end

  def tracking(mirakl_order_id, shipping_info)
    @response = SpreeMirakl::Request.new(@store).put("/api/orders/#{mirakl_order_id}/tracking?shop_id=#{@store.shop_id}", shipping_info)
  end

  def ship(mirakl_order_id)
    @response = SpreeMirakl::Request.new(@store).put("/api/orders/#{mirakl_order_id}/ship?shop_id=#{@store.shop_id}", '')
  end

  def account
    @response = SpreeMirakl::Request.new(@store).get("/api/account")
  end

  def carriers
    @response = SpreeMirakl::Request.new(@store).get("/api/shipping/carriers?shop_id=#{@store.shop_id}")
  end

  def refund_reasons
    @response = SpreeMirakl::Request.new(@store).get("/api/reasons/REFUND?shop_id=#{@store.shop_id}")
  end

  def get_order(mirakl_order_id)
    @response = SpreeMirakl::Request.new(@store).get("/api/orders?order_ids=#{mirakl_order_id}&shop_id=#{@store.shop_id}")
  end

  def get_order_state(state)
    @response = SpreeMirakl::Request.new(@store).get("/api/orders?order_state_codes=#{state}&shop_id=#{@store.shop_id}&max=50&limit=50")
  end

  def accept_order(mirakl_order_id, json_data)
    @response = SpreeMirakl::Request.new(@store).put("/api/orders/#{mirakl_order_id}/accept?shop_id=#{@store.shop_id}", ({ order_lines: json_data }).to_json)
  end

  def refund(return_json)
    @response = SpreeMirakl::Request.new(@store).put("/api/orders/refund?shop_id=#{@store.shop_id}", ({ refunds: return_json }).to_json)
  end

  def cancel(mirakl_order_number)
    @response = SpreeMirakl::Request.new(@store).put("/api/orders/#{mirakl_order_number}/cancel?shop_id=#{@store.shop_id}", '')
  end

  def offers
    @response = SpreeMirakl::Request.new(@store).get("/api/offers?shop_id=#{@store.shop_id}&max=100&limit=100")
  end

  def update_offers(offer_json)
    @response = SpreeMirakl::Request.new(@store).post("/api/offers?shop_id=#{@store.shop_id}", ({ offers: offer_json }).to_json)
  end

  def get_offer(offer_id)
    @response = SpreeMirakl::Request.new(@store).get("/api/offers/#{offer_id}?shop_id=#{@store.shop_id}")
  end

end