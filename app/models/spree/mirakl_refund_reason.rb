module Spree
  class MiraklRefundReason < ActiveRecord::Base
    belongs_to :mirakl_store

    has_many :return_authorization_reason_to_mirakl_refund_reasons, dependent: :destroy
    has_many :return_authorization_reasons, through: :return_authorization_reason_to_mirakl_refund_reasons
  end
end
