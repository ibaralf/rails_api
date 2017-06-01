Rails.application.routes.draw do
  resources :todos do
    resources :items
  end
  
  get '/slash' => 'slashinator#index'
  post '/slash' => 'slashinator#parseit'
end
