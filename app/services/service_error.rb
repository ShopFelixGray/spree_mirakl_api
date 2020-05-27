class ServiceError < StandardError
  attr_reader :messages

  def initialize(messages)
    @messages = messages
  end
end
