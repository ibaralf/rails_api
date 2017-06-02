Rails.application.routes.draw do
  resources :todos do
    resources :items
  end
  
  get '/slash' => 'slashinator#index'
  post '/slash' => 'slashinator#parseit'
  post '/selected_instance' => 'slashinator#selected_instance'
end
