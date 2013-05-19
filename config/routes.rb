Shiita::Application.routes.draw do

  resources :items do
    member do
      post "stock"
      delete "stock" => :unstock
      post "comment"
    end
  end

  controller :tags do
    get "/tags" => :index, as: :tags
    get "/tags/:name" => :show, as: :tag
    get "/tags/:name/followers" => :followers, as: :tag_followers
    post "/tags/:name/follow" => :follow, as: :tag_follow
    delete "/tags/:name/follow" => :unfollow, as: :tag_follow
  end

  scope "users", controller: :users do
    get "" => :index, as: :users

    scope ":email", constraints: { email: /[^\/]+/ } do
      get "" => :show, as: :user
      get "stocks" => :stocks, as: :stocks_user
      get "followings" => :followings, as: :followings_user
      get "followers" => :followers, as: :followers_user
      post "follow" => :follow, as: :follow_user
      delete "follow" => :unfollow
    end
  end

  controller :sessions do
    get "/login" => redirect("/auth/google_oauth2"), as: :login
    get '/auth/:provider/callback' => :callback
    delete '/logout' => :destroy, as: :logout
  end

  %w(about help).each do |name|
    get "/#{name}" => "home#help"
  end

  root to: "home#index"

end
