module Spree
  class MiraklStore < ActiveRecord::Base
    belongs_to :user
    has_many :mirakl_refund_reasons, dependent: :destroy
    has_many :mirakl_shipping_options, dependent: :destroy
    has_many :mirakl_store_carriers, dependent: :destroy
    has_many :mirakl_transactions

    validates :name, :api_key, :url, :user_id, presence: true
    validates :name, :api_key, :url, uniqueness: { case_sensitive: false }

    scope :active, -> { where(active: true) }

    after_create :get_carriers_from_mirakl

    before_destroy :check_for_orders, prepend: true

    def check_for_orders
      return unless mirakl_transactions.present?

      errors[:base] << Spree.t(:mirakl_store_cant_be_destroyed)
      false
    end

    def get_carriers_from_mirakl
      mirakl_request = SpreeMirakl::Api.new(self)
      request = mirakl_request.carriers()

      raise Exception.new(Spree.t(:carrier_error, shop_id: self.shop_id)) unless request.success?

      carriers = JSON.parse(request.body, {symbolize_names: true})[:carriers]

      carriers.each do |carrier|
        Spree::MiraklStoreCarrier.find_or_create_by(label: carrier[:label].downcase, code: carrier[:code], mirakl_store: self)
      end
    end
  end
end
