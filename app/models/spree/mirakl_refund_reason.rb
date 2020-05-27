module Spree
  class MiraklRefundReason < ActiveRecord::Base
    belongs_to :mirakl_store
    has_many :mirakl_refund_reason_to_refund_reasons, dependent: :destroy
    has_many :refund_reasons, through: :mirakl_refund_reason_to_refund_reasons
  end
end
