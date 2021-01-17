Railspress::Engine.routes.draw do

  resources :options

  if !Railspress.posts_permalink_prefix.nil?
    scope path: Railspress.posts_permalink_prefix do
      get '' => 'railspress/home#posts', as: :all_posts
      get 'page/:page' => 'railspress/home#posts'
      get ':year' => 'railspress/archive#year_archive', constraints: {year: /20[12]\d/}, as: :year_archive_posts
      get ':year/:monthnum' => 'railspress/archive#month_archive', constraints: {year: /20[12]\d/, monthnum: /(0?\d)|10|11|12/}

      get 'tag/:slug' => 'railspress/archive#taxonomy', defaults: {taxonomy: 'post_tag'}
      get 'category/:slug' => 'railspress/archive#taxonomy', defaults: {taxonomy: 'category'}, as: :category_posts
      get 'author/:slug' => 'railspress/archive#author', defaults: {taxonomy: 'author'}, as: :authors_posts
      get ':taxonomy/:slug' => 'railspress/archive#taxonomy'

      get ':name' => 'railspress/posts#singular'
    end
  else
    get 'archive/:taxonomy/:slug' => 'railspress/archive#taxonomy'
    get 'tag/:slug' => 'railspress/archive#taxonomy', defaults: {taxonomy: 'post_tag'}
    get 'category/:slug' => 'railspress/archive#taxonomy', defaults: {taxonomy: 'category'}, as: :category_posts
    get 'author/:slug/page/:page' => 'railspress/archive#author', defaults: {taxonomy: 'author'}
    get 'author/:slug' => 'railspress/archive#author', defaults: {taxonomy: 'author'}, as: :authors_posts
  end

  # get 'posts/:name' => 'railspress/posts#singular'

  get '*slug' => 'railspress/posts#singular', as: :show_page
  # get '*pagename' => 'pages#index'

  get '/' => 'railspress/home#index'

end
