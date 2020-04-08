Railspress::Engine.routes.draw do

  resources :options

  get 'posts' => 'posts#index'
  get 'posts/:year' => 'posts#by_year', constraints: {year: /20[12]\d/}, as: :news_of_year
  get 'posts/:year/:month' => 'posts#by_month', constraints: {year: /20[12]\d/, month: /(0?\d)|10|11|12/}
  get 'posts/:slug' => 'posts#show'
  get 'posts/archive/:taxonomy/:slug' => 'posts#archive'
  get 'posts/tag/:slug' => 'posts#archive', defaults: {taxonomy: 'post_tag'}
  get 'posts/category/:slug' => 'posts#archive', defaults: {taxonomy: 'category'}

  get '*slug' => 'pages#show'
  get '/' => 'pages#home'

end
