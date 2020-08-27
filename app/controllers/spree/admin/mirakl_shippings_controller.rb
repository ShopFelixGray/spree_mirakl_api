module Spree
  module Admin
    class MiraklShippingsController < Spree::Admin::ResourceController
      before_action :set_mirakl_store
      def refresh_carriers
        @mirakl_store.get_carriers_from_mirakl
        flash[:notice] = Spree.t(:carriers_synced)
        redirect_to admin_mirakl_stores_path
      end

      def shipping_options
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

      def shipping_to_shipping_method
        
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

      private

      def set_mirakl_store
        @mirakl_store = Spree::MiraklStore.find(params[:mirakl_store_id])
      end
    end
  end
end
