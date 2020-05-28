module Spree
  class MiraklRefundReasonToRefundReason < ActiveRecord::Base
    belongs_to :mirakl_refund_reason
    belongs_to :refund_reason
  end
end

