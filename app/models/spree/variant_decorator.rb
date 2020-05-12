Spree::Variant.class_eval do

  def quantity_check
    self.total_on_hand > 0 ? self.total_on_hand : 0
  end

end