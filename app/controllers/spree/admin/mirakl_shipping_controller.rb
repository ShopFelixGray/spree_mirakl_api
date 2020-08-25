module Spree
  module Admin
    class MiraklShippingController < Spree::Admin::ResourceController
      def mirakl_refresh_carriers
        store = Spree::MiraklStore.find_by(params[:mirakl_store_id])
        store.get_carriers_from_mirakl
        flash[:notice] = Spree.t(:carriers_synced)
        redirect_to admin_mirakl_stores_path
      end

      def mirakl_shipping_options
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

      def mirakl_shipping_to_shipping_method
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
    end
  end
end
