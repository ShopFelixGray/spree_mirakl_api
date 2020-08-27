Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  namespace :admin do
    resources :mirakl_stores do
      get :refresh_inventory
      get :reason_mapper
      put :map_refunds

      resource :mirakl_shipping do
        get :refresh_carriers
        get :shipping_options
        post :shipping_to_shipping_method
      end
    end
  end
end
