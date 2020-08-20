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
        begin
          ActiveRecord::Base.transaction do
            @mirakl_store = Spree::MiraklStore.new(mirakl_store_params)

            if @mirakl_store.save
              mirakl_request = SpreeMirakl::Api.new(@mirakl_store)
              request = mirakl_request.account
              if request.success?
                @mirakl_store.update(shop_id: JSON.parse(request.body, symbolize_names: true)[:shop_id])
                reasons_request_sync(mirakl_request)
              else
                raise Exception.new(Spree.t(:shop_id_issue))
              end
              flash[:success] = Spree.t(:mirakl_store_created)
              redirect_to admin_mirakl_stores_path
            else
             raise Exception.new(@mirakl_store.errors.full_messages)
            end
          end
        rescue => e
          flash[:error] = e.message
          render :new
        end
      end

      def edit
        @mirakl_store = Spree::MiraklStore.includes(mirakl_refund_reasons: [:return_authorization_reasons]).find(params[:id])
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
        @mirakl_store = Spree::MiraklStore.includes(mirakl_refund_reasons: [:return_authorization_reasons]).find(params[:mirakl_store_id])
        reasons_request = SpreeMirakl::Api.new(@mirakl_store).refund_reasons()
        if reasons_request.success?
          refund_types = JSON.parse(reasons_request.body, symbolize_names: true)[:reasons]
          refund_types.each do |refund_type|
            unless @mirakl_store.mirakl_refund_reasons.where(label: refund_type[:label], code: refund_type[:code]).present?
              Spree::MiraklRefundReason.create!(label: refund_type[:label], code: refund_type[:code], mirakl_store: @mirakl_store)
            end
          end
        else
          flash[:error] = Spree.t(:sync_refund_issue)
          redirect_to admin_mirakl_stores_path
        end
      end

      def map_refunds
        begin
          Spree::ReturnAuthorizationReason.all.each do |return_authorization_reason|
            if params[:return_authorization_reason][return_authorization_reason.id.to_s]
              @mirakl_refund_reason = Spree::MiraklRefundReason.find(params[:return_authorization_reason][return_authorization_reason.id.to_s])
              @mirakl_refund_reason.update(return_authorization_reason_ids: params[:return_authorization_reason].select{|key, hash|  hash == @mirakl_refund_reason.id.to_s }.keys)
            end
          end
          flash[:notice] = Spree.t(:updated)
        rescue => e
          flash[:error] = e.message
        end
        redirect_to admin_mirakl_stores_path
      end

      def shipping_mapper
        @mirakl_store = Spree::MiraklStore.includes(mirakl_shipping_options: [:shipping_methods]).find(params[:mirakl_store_id])
        reasons_request = SpreeMirakl::Api.new(@mirakl_store).shipping_options()
        if reasons_request.success?
          shipping_options = JSON.parse(reasons_request.body, symbolize_names: true)[:shippings]
          shipping_options.each do |shipping_option|
            unless @mirakl_store.mirakl_shipping_options.where(shipping_type_label: shipping_option[:shipping_type_label], shipping_type_code: shipping_option[:shipping_type_code]).present?
              Spree::MiraklShippingOption.create!(shipping_type_label: shipping_option[:shipping_type_label], shipping_type_code: shipping_option[:shipping_type_code], mirakl_store: @mirakl_store)
            end
          end
          @mirakl_shipping_options = @mirakl_store.mirakl_shipping_options
        else
          flash[:error] = Spree.t(:sync_refund_issue)
          redirect_to admin_mirakl_stores_path
        end
      end

      def map_shipping
        @mirakl_store = Spree::MiraklStore.find(params[:mirakl_store_id])
        begin
          @mirakl_store.mirakl_shipping_options.all.each do |shipping_option|
            if params[:shipping_option][shipping_option.id.to_s]
              shipping_option.update(shipping_method_ids: params[:shipping_option][shipping_option.id.to_s])
            end
          end
          flash[:notice] = Spree.t(:updated)
        rescue => e
          flash[:error] = e.message
        end
        redirect_to admin_mirakl_stores_path
      end
    
      def refresh_inventory
        MiraklInventoryUpdateJob.perform_later(params[:mirakl_store_id])
        flash[:notice] = Spree.t(:refresh_queued)
        redirect_to admin_mirakl_stores_path
      end

      def refresh_carriers
        store = Spree::MiraklStore.find_by(params[:mirakl_store_id])
        store.get_carriers_from_mirakl
        flash[:notice] = Spree.t(:carriers_synced)
        redirect_to admin_mirakl_stores_path
      end
    
      private
    
      def set_mirakl_store
        @mirakl_store = Spree::MiraklStore.includes(mirakl_refund_reasons: [:return_authorization_reasons]).find(params[:id])
      end
    
      def mirakl_store_params
        params.require(:mirakl_store).permit(:name, :api_key, :url, :active, :user_id)
      end

      def reasons_request_sync(mirakl_request)
        reasons_request = mirakl_request.refund_reasons()
        if reasons_request.success?
          refund_types = JSON.parse(reasons_request.body, symbolize_names: true)[:reasons]
          refund_creates(refund_types)
        else
          raise Expection(Spree.t(:sync_refund_issue))
        end
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
