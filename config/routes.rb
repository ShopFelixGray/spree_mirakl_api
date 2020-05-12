Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  namespace :admin do
    resources :mirakl_stores do
      get :refresh_inventory
      get :reason_mapper
      put :map_refunds
    end
  end
end
