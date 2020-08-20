Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  namespace :admin do
    resources :mirakl_stores do
      get :refresh_inventory
      get :refresh_carriers
      get :reason_mapper
      put :map_refunds
      get :shipping_mapper
      put :map_shipping
    end
  end
end
