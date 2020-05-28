module Spree
  class ReturnAuthorizationReasonToMiraklRefundReason < ActiveRecord::Base
    belongs_to :mirakl_refund_reason
    belongs_to :return_authorization_reason
  end
end
