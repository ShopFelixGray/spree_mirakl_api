class Spree::MiraklStore < ActiveRecord::Base
  belongs_to :user
  has_many :mirakl_refund_reasons, dependent: :destroy

  validates :name, :api_key, :url, presence: true
  validates :name, :api_key, :url, :uniqueness => {:case_sensitive => false}

  after_create :pull_in_shop_info

  def pull_in_shop_info
    # TODO: Look to refactor if possible
    if self.shop_id.nil?
      headers = { 'Authorization': api_key, 'Accept': 'application/json' }
      request = HTTParty.get("#{url}/api/account", headers: headers)

      if request.success?
        self.update(shop_id: JSON.parse(request.body)['shop_id'])

        request = HTTParty.get("#{url}/api/reasons/REFUND", headers: headers)
        if request.success?
          refund_types = JSON.parse(request.body)['reasons']

          refund_types.each do |refund_type|
            unless mirakl_refund_reasons.where(label: refund_type['label'], code: refund_type['code']).present?
              Spree::MiraklRefundReason.create!(label: refund_type['label'], code: refund_type['code'], mirakl_store: self)
            end
          end
        else
          # TODO: ERROR
        end
      else
        # TODO: ERROR
      end
    end
  end
end