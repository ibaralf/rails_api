Rails.application.routes.draw do
  resources :todos do
    resources :items
  end
  
  get '/slash' => 'slircle#index'
  post '/slash' => 'slircle#parseit'
  post '/slash_action' => 'slircle#slash_action'
end
