Railspress::Engine.routes.draw do

  resources :options, controller: 'railspress/options'

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

      get ':name' => 'railspress/posts#singular', as: :show_post
    end
  else
    get 'archive/:taxonomy/:slug' => 'railspress/archive#taxonomy'
    get 'tag/:slug' => 'railspress/archive#taxonomy', defaults: {taxonomy: 'post_tag'}
    get 'category/:slug' => 'railspress/archive#taxonomy', defaults: {taxonomy: 'category'}, as: :category_posts
    get 'author/:slug/page/:page' => 'railspress/archive#author', defaults: {taxonomy: 'author'}
    get 'author/:slug' => 'railspress/archive#author', defaults: {taxonomy: 'author'}, as: :authors_posts
  end

  if !Railspress.pages_permalink_prefix.nil?
    scope path: Railspress.pages_permalink_prefix do
      get '*slug' => 'railspress/posts#singular', as: :show_page
    end
  else
    get '*slug' => 'railspress/posts#singular', as: :show_page
  end

  get '/' => 'railspress/home#index'

end
