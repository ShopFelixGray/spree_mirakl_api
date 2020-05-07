Spree::Order.class_eval do
  has_one :mirakl_transaction, dependent: :destroy
end