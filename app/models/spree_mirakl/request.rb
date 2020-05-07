class SpreeMirakl::Request
  attr_reader :request, :store

  def initialize(store)
    @store = store
    @request = nil
  end

  def get(path)
    headers = { 'Authorization': @store.api_key, 'Accept': 'application/json' }
    @request = HTTParty.get("#{@store.url}#{path}", headers: headers)
  end

  def put(path, data)
    headers = { 'Authorization': @store.api_key, 'Accept': 'application/json', 'Content-Type': 'application/json' }
    @request = HTTParty.put("#{@store.url}#{path}", body: data, headers: headers)
    @request
  end

  def body
    @request.body
  end

  def success?
    @request.success?
  end

  def response_code
    @request.code
  end

  private

  

end