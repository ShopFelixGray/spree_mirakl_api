class Spree::MiraklStore < ActiveRecord::Base
  belongs_to :user

  validates :name, :api_key, :url, presence: true
  validates :name, :api_key, :url, :uniqueness => {:case_sensitive => false}
end