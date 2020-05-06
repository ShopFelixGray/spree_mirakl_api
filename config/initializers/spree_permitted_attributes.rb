module Spree
  module PermittedAttributes
    ATTRIBUTES << :mirakl_store_attributes

    @@mirakl_store_attributes = [:name, :api_key, :url, :active, :user_id]
  end
end