Shiita::Application.routes.draw do

  match '/auth/:provider/callback', :to => 'sessions#callback'

  root to: "home#index"

end
