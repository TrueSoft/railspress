Railspress::Engine.routes.draw do

  resources :options

  get 'posts' => 'posts#index'
  get 'posts/:year' => 'posts#by_year', constraints: {year: /20[12]\d/}, as: :news_of_year
  get 'posts/:year/:month' => 'posts#by_month', constraints: {year: /20[12]\d/, month: /(0?\d)|10|11|12/}
  get 'posts/:slug' => 'posts#show', as: :show_post
  get 'posts/show/:id' => 'posts#show_id', constraints: {id: /\d+/}
  get 'posts/tag/:slug' => 'posts#tag'

  get '*slug' => 'pages#show', as: :show_page
  get '/' => 'pages#home'

end
