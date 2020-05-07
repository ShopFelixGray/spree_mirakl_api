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

  def edit;end

  def update
    @mirakl_store.update(mirakl_store_params)

    if @mirakl_store.save
      flash[:success] = Spree.t(:mirakl_store_updated)
      redirect_to admin_mirakl_stores_path
    else
      flash[:error] = @mirakl_store.errors.full_messages
      render :edit
    end
  end

  def destory
    if @mirakl_store.destory
      flash[:success] = Spree.t(:mirakl_store_destroyed)
      redirect_to admin_mirakl_stores_path
    else
      flash[:error] = @mirakl_store.errors.full_messages
      redirect_to :index
    end
  end

  private

  def set_mirakl_store
    @mirakl_store = Spree::MiraklStore.find(params[:id])
  end

  def mirakl_store_params
    params.require(:mirakl_store).permit(:name, :api_key, :url, :active, :user_id)
  end
end 