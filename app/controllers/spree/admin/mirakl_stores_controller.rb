class Spree::Admin::MiraklStoresController < Spree::Admin::ResourceController

  def index
    @mirakl_stores = Spree::MiraklStore.all
  end

  def new
    @mirakl_store = Spree::MiraklStore.new
  end

  def create
    @mirakl_store = Spree::MiraklStore.new(mirakl_store_params)

    if @mirakl_store.save
      redirect_to admin_mirakl_stores_path
    else
      render :new
    end
  end

  def edit
    @mirakl_store = Spree::MiraklStore.includes(mirakl_refund_reasons: [:refund_reasons]).find(params[:id])
  end

  def update
    @mirakl_store.update(mirakl_store_params)

    if @mirakl_store.save
      redirect_to admin_mirakl_stores_path
    else
      render :edit
    end
  end

  def destory
    if @mirakl_store.destory
      redirect_to admin_mirakl_stores_path
    else
      redirect_to :index
    end
  end

  def map_refunds
    begin
      Spree::RefundReason.all.each do |refund_reason|
        if params[refund_reason.id.to_s]
          @mirakl_refund_reason = Spree::MiraklRefundReason.find(params[refund_reason.id.to_s])
          @mirakl_refund_reason.update(refund_reason_ids: [refund_reason.id])
        end
      end
      flash[:sucess] = "Updated"
      redirect_to edit_admin_mirakl_store_path(@mirakl_refund_reason.mirakl_store)
    rescue => exception
      flash[:error] = exception.message
      redirect_to :index
    end
  end

  private

  def set_mirakl_store
    @mirakl_store = Spree::MiraklStore.includes(mirakl_refund_reasons: [:refund_reasons]).find(params[:id])
  end

  def mirakl_store_params
    params.require(:mirakl_store).permit(Spree::PermittedAttributes.mirakl_store_attributes)
  end
end 