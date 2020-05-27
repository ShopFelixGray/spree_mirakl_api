module Spree
  class MiraklStore < ActiveRecord::Base
    belongs_to :user
    has_many :mirakl_refund_reasons, dependent: :destroy
    has_many :mirakl_transactions
  
    validates :name, :api_key, :url, :user_id, presence: true
    validates :name, :api_key, :url, uniqueness: { case_sensitive: false }
  
    scope :active, -> { where(active: true) }
  
    before_destroy :check_for_orders, prepend: true
  
    def check_for_orders
      return unless mirakl_transactions.present?
  
      errors[:base] << Spree.t(:mirakl_store_cant_be_destroyed)
      false
    end
  end
end
