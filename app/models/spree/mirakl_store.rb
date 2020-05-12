class Spree::MiraklStore < ActiveRecord::Base
  belongs_to :user
  has_many :mirakl_refund_reasons, dependent: :destroy

  validates :name, :api_key, :url, :user_id, presence: true
  validates :name, :api_key, :url, :uniqueness => {:case_sensitive => false}

  after_create :pull_in_shop_info

  scope :active, -> { where(active: true) }

  def pull_in_shop_info
    # TODO: Look to refactor if possible
    if self.shop_id.nil?
      mirakl_request = SpreeMirakl::Api.new(self)
      request = mirakl_request.account()

      if request.success?
        self.update(shop_id: JSON.parse(request.body, {symbolize_names: true})[:shop_id])

        reasons_request = mirakl_request.refund_reasons()
        if reasons_request.success?
          refund_types = JSON.parse(reasons_request.body, {symbolize_names: true})[:reasons]

          refund_types.each do |refund_type|
            unless mirakl_refund_reasons.where(label: refund_type[:label], code: refund_type[:code]).present?
              Spree::MiraklRefundReason.create!(label: refund_type[:label], code: refund_type[:code], mirakl_store: self)
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
    reasons_request = SpreeMirakl::Api.new(self).refund_reasons()
    if reasons_request.success?
      refund_types = JSON.parse(reasons_request.body, {symbolize_names: true})[:reasons]

      refund_types.each do |refund_type|
        unless mirakl_refund_reasons.where(label: refund_type[:label], code: refund_type[:code]).present?
          Spree::MiraklRefundReason.create!(label: refund_type[:label], code: refund_type[:code], mirakl_store: self)
        end
      end
    else
      raise Exception.new('Issue syncing Refund Reasons. Please try again')
    end
  end

  def sync_shop_id
    request = SpreeMirakl::Api.new(self).account()

    if request.success?
      self.update(shop_id: JSON.parse(request.body, {symbolize_names: true})[:shop_id])
    else
      raise Exception.new('Issue getting shop ID. Please try again')
    end
  end

end