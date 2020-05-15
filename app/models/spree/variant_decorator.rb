Spree::Variant.class_eval do

  def quantity_check
    # If item is no longer available remove all stock
    if self.available?
      self.total_on_hand > 0 ? self.total_on_hand : 0
    else
      0
    end
  end

end