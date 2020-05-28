require 'httparty'

class SpreeMirakl::Request
  attr_reader :request, :store

  def initialize(store)
    @store = store
    @request = nil
  end

  def get(path)
    header = { 'Authorization': @store.api_key, 'Accept': 'application/json' }
    @request = HTTParty.get("#{@store.url}#{path}", headers: header)
  end

  def put(path, data)
    @request = HTTParty.put("#{@store.url}#{path}", body: data, headers: headers)
  end

  def post(path, data)
    @request = HTTParty.post("#{@store.url}#{path}", body: data, headers: headers)
  end

  def headers
    { 'Authorization': @store.api_key, 'Accept': 'application/json', 'Content-Type': 'application/json' }
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
end
