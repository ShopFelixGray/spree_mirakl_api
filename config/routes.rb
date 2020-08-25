Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  namespace :admin do
    get '/mirakl_shipping/:mirakl_store_id/mirakl_refresh_carriers' => 'mirakl_shipping#mirakl_refresh_carriers', as: :mirakl_refresh_carriers
    get '/mirakl_shipping/:mirakl_store_id/mirakl_shipping_options' => 'mirakl_shipping#mirakl_shipping_options', as: :mirakl_shipping_options
    post '/mirakl_shipping/:mirakl_store_id/mirakl_shipping_to_shipping_method' => 'mirakl_shipping#mirakl_shipping_to_shipping_method', as: :mirakl_shipping_to_shipping_method

    resources :mirakl_stores do
      get :refresh_inventory
      get :reason_mapper
      put :map_refunds
    end
  end
end
