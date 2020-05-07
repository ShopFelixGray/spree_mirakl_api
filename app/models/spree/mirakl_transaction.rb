class Spree::MiraklTransaction < ActiveRecord::Base
  belongs_to :order
  belongs_to :return_authorization

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