module Spree
  class MiraklTransaction < ActiveRecord::Base
    belongs_to :order
    belongs_to :mirakl_store

    def reusable_sources(_order)
      []
    end

    def self.with_payment_profile
      []
    end

    def name
      'Mirakl'
    end
  end
end
