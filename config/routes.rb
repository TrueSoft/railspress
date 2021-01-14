Railspress::Engine.routes.draw do

  resources :options

  # get 'posts' => 'railspress/home#posts'
  get 'posts/:year' => 'railspress/archive#year_archive', constraints: {year: /20[12]\d/}, as: :year_archive_posts
  get 'posts/:year/:monthnum' => 'railspress/archive#month_archive', constraints: {year: /20[12]\d/, monthnum: /(0?\d)|10|11|12/}

  get 'archive/:taxonomy/:slug' => 'railspress/archive#taxonomy'
  get 'tag/:slug' => 'railspress/archive#taxonomy', defaults: {taxonomy: 'post_tag'}
  get 'category/:slug' => 'railspress/archive#taxonomy', defaults: {taxonomy: 'category'}, as: :category_posts
  get 'author/:slug/page/:page' => 'railspress/archive#author', defaults: {taxonomy: 'author'}
  get 'author/:slug' => 'railspress/archive#author', defaults: {taxonomy: 'author'}, as: :authors_posts

  get 'posts/:name' => 'posts#single'

  get '*slug' => 'railspress/posts#single', as: :show_page
  # get '*pagename' => 'pages#index'

  get '/' => 'railspress/home#index'

end
