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
      flash[:success] = Spree.t(:mirakl_store_created)
      redirect_to admin_mirakl_stores_path
    else
      flash[:error] = @mirakl_store.errors.full_messages
      render :new
    end
  end

  def edit
    @mirakl_store = Spree::MiraklStore.includes(mirakl_refund_reasons: [:refund_reasons]).find(params[:id])
  end

  def update
    @mirakl_store.update(mirakl_store_params)

    if @mirakl_store.save
      flash[:notice] = Spree.t(:mirakl_store_updated)
      redirect_to admin_mirakl_stores_path
    else
      flash[:error] = @mirakl_store.errors.full_messages
      render :edit
    end
  end

  def destory
    if @mirakl_store.destory
      flash[:notice] = Spree.t(:mirakl_store_destroyed)
      redirect_to admin_mirakl_stores_path
    else
      flash[:error] = @mirakl_store.errors.full_messages
      redirect_to :index
    end
  end

  def reason_mapper
    @mirakl_store = Spree::MiraklStore.includes(mirakl_refund_reasons: [:refund_reasons]).find(params[:mirakl_store_id])
    @mirakl_store.sync_reasons
  end

  def map_refunds
    begin
      Spree::RefundReason.all.each do |refund_reason|
        if params[:refund_reason][refund_reason.id.to_s]
          @mirakl_refund_reason = Spree::MiraklRefundReason.find(params[:refund_reason][refund_reason.id.to_s])
          @mirakl_refund_reason.update(refund_reason_ids: params[:refund_reason].select{|key, hash|  hash == @mirakl_refund_reason.id.to_s }.keys)
        end
      end
      flash[:notice] = "Updated"
      redirect_to admin_mirakl_store_reason_mapper_path(@mirakl_refund_reason.mirakl_store)
    rescue => exception
      flash[:error] = exception.message
      redirect_to :index
    end
  end

  def refresh_inventory
    MiraklInventoryUpdateJob.perform_later(params[:mirakl_store_id])
    flash[:notice] = "Refresh Queued"
    redirect_to admin_mirakl_stores_path
  end

  private

  def set_mirakl_store
    @mirakl_store = Spree::MiraklStore.includes(mirakl_refund_reasons: [:refund_reasons]).find(params[:id])
  end

  def mirakl_store_params
    params.require(:mirakl_store).permit(:name, :api_key, :url, :active, :user_id)
  end
end 