Rails.application.routes.draw do
  #resources :todos do
  #  resources :items
  #end
  
  get '/slash' => 'slircle#index'
  post '/slash' => 'slircle#parseit'
  post '/slash_action' => 'slircle#slash_action'

  get '/sitestat' => 'thredup_monitor#run_health_check'
  post '/sitestat' => 'thredup_monitor#set_channel'

end
