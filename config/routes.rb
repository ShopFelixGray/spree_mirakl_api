Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  namespace :admin do
    resources :mirakl_stores do
      put :map_refunds
    end
  end
end
