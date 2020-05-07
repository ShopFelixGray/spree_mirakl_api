class Spree::MiraklStore < ActiveRecord::Base
  belongs_to :user
  has_many :mirakl_refund_reasons, dependent: :destroy

  validates :name, :api_key, :url, presence: true
  validates :name, :api_key, :url, :uniqueness => {:case_sensitive => false}

  after_create :pull_in_shop_info

  def pull_in_shop_info
    # TODO: Look to refactor if possible
    if self.shop_id.nil?
      mirakl_request = SpreeMirakl::Request.new(self)
      request = mirakl_request.get("/api/account")

      if request.success?
        self.update(shop_id: JSON.parse(request.body)['shop_id'])

        reasons_request = mirakl_request.get("/api/reasons/REFUND?shop_id=#{self.shop_id}")
        if reasons_request.success?
          refund_types = JSON.parse(request.body)['reasons']

          refund_types.each do |refund_type|
            unless mirakl_refund_reasons.where(label: refund_type['label'], code: refund_type['code']).present?
              Spree::MiraklRefundReason.create!(label: refund_type['label'], code: refund_type['code'], mirakl_store: self)
            end
          end
        else
          raise Exception.new('Issue syncing Refund Reasons. Please try again')
        end
      else
        raise Exception.new('Issue getting shop ID. Please try again')
      end
    end
  end

  def sync_reasons
    mirakl_request = SpreeMirakl::Request.new(self)
    reasons_request = mirakl_request.get("/api/reasons/REFUND?shop_id=#{self.shop_id}")
    if reasons_request.success?
      refund_types = JSON.parse(request.body)['reasons']

      refund_types.each do |refund_type|
        unless mirakl_refund_reasons.where(label: refund_type['label'], code: refund_type['code']).present?
          Spree::MiraklRefundReason.create!(label: refund_type['label'], code: refund_type['code'], mirakl_store: self)
        end
      end
    else
      raise Exception.new('Issue syncing Refund Reasons. Please try again')
    end
  end

  def sync_shop_id
    mirakl_request = SpreeMirakl::Request.new(self)
    request = mirakl_request.get("/api/account")

    if request.success?
      self.update(shop_id: JSON.parse(request.body)['shop_id'])
    else
      raise Exception.new('Issue getting shop ID. Please try again')
    end
  end

end