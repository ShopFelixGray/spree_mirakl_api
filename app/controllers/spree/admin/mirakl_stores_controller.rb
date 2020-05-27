module Spree
  module Admin
    class MiraklStoresController < Spree::Admin::ResourceController
      def index
        @mirakl_stores = Spree::MiraklStore.all
      end
    
      def new
        @mirakl_store = Spree::MiraklStore.new
      end
    
      def create
        @mirakl_store = Spree::MiraklStore.new(mirakl_store_params)
    
        if @mirakl_store.save
          mirakl_request = SpreeMirakl::Api.new(@mirakl_store)
          request = mirakl_request.account
          if request.success?
            @mirakl_store.update(shop_id: JSON.parse(request.body, symbolize_names: true)[:shop_id])
            reasons_request = mirakl_request.refund_reasons()
            if reasons_request.success?
              refund_types = JSON.parse(reasons_request.body, symbolize_names: true)[:reasons]
              refund_creates(refund_types)
            else
              @mirakl_store.destory
              flash[:error] = 'Issue syncing Refund Reasons. Please try again'
              render :new
            end
          else
            @mirakl_store.destory
            flash[:error] = 'Issue getting shop ID. Please try again'
            render :new
          end
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
        else
          flash[:error] = @mirakl_store.errors.full_messages
        end
        redirect_to admin_mirakl_stores_path
      end
    
      def reason_mapper
        @mirakl_store = Spree::MiraklStore.includes(mirakl_refund_reasons: [:refund_reasons]).find(params[:mirakl_store_id])
        reasons_request = SpreeMirakl::Api.new(@mirakl_store).refund_reasons()
        if reasons_request.success?
          refund_types = JSON.parse(reasons_request.body, symbolize_names: true)[:reasons]
          refund_types.each do |refund_type|
            unless @mirakl_store.mirakl_refund_reasons.where(label: refund_type[:label], code: refund_type[:code]).present?
              Spree::MiraklRefundReason.create!(label: refund_type[:label], code: refund_type[:code], mirakl_store: @mirakl_store)
            end
          end
        else
          flash[:error] = 'Issue syncing Refund Reasons. Please try again'
          redirect_to admin_mirakl_stores_path
        end
      end
    
      def map_refunds
        begin
          Spree::RefundReason.all.each do |refund_reason|
            if params[:refund_reason][refund_reason.id.to_s]
              @mirakl_refund_reason = Spree::MiraklRefundReason.find(params[:refund_reason][refund_reason.id.to_s])
              @mirakl_refund_reason.update(refund_reason_ids: params[:refund_reason].select{|key, hash|  hash == @mirakl_refund_reason.id.to_s }.keys)
            end
          end
          flash[:notice] = 'Updated'
        rescue => e
          flash[:error] = e.message
        end
        redirect_to admin_mirakl_stores_path
      end
    
      def refresh_inventory
        MiraklInventoryUpdateJob.perform_later(params[:mirakl_store_id])
        flash[:notice] = 'Refresh Queued'
        redirect_to admin_mirakl_stores_path
      end
    
      private
    
      def set_mirakl_store
        @mirakl_store = Spree::MiraklStore.includes(mirakl_refund_reasons: [:refund_reasons]).find(params[:id])
      end
    
      def mirakl_store_params
        params.require(:mirakl_store).permit(:name, :api_key, :url, :active, :user_id)
      end
    
      def refund_creates(refund_types)
        refund_types.each do |refund_type|
          unless  @mirakl_store.mirakl_refund_reasons.where(label: refund_type[:label], code: refund_type[:code]).present?
            Spree::MiraklRefundReason.create!(label: refund_type[:label], code: refund_type[:code], mirakl_store: @mirakl_store)
          end
        end
      end
    end
    
  end
end
