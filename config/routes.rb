Railspress::Engine.routes.draw do

  resources :options

  # get 'posts' => 'railspress/home#posts'
  get 'posts/:year' => 'posts#by_year', constraints: {year: /20[12]\d/}, as: :news_of_year
  get 'posts/:year/:month' => 'posts#by_month', constraints: {year: /20[12]\d/, month: /(0?\d)|10|11|12/} # replace with monthnum?

  get 'archive/:taxonomy/:slug' => 'railspress/posts#archive'
  get 'tag/:slug' => 'railspress/posts#archive', defaults: {taxonomy: 'post_tag'}
  get 'category/:slug' => 'railspress/posts#archive', defaults: {taxonomy: 'category'}
  get 'author/:slug/page/:page' => 'railspress/posts#archive', defaults: {taxonomy: 'author'}
  get 'author/:slug' => 'railspress/posts#archive', defaults: {taxonomy: 'author'}, as: :authors_posts

  get 'posts/:name' => 'posts#single'

  get '*slug' => 'railspress/posts#single', as: :show_page
  # get '*pagename' => 'pages#index'

  get '/' => 'railspress/home#index'

end
