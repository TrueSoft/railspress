Rails.application.routes.draw do

  get 'news' => 'railspress/posts#index', as: :all_posts
  get 'news/:year' => 'railspress/posts#by_year', constraints: {year: /20[12]\d/}, as: :news_of_year
  get 'news/:year/:month' => 'railspress/posts#by_month', constraints: {year: /20[12]\d/, month: /(0?\d)|10|11|12/}
  scope :news do
    get ':slug' => 'railspress/posts#single'
    get 'tag/:slug' => 'railspress/posts#archive', defaults: {taxonomy: 'post_tag'}
    get ':taxonomy/:slug' => 'railspress/posts#archive'
  end

  get 'category/:slug' => 'railspress/posts#archive', defaults: {taxonomy: 'category'}
  get 'tag/:slug' => 'railspress/posts#archive', defaults: {taxonomy: 'post_tag'}
  get 'author/:slug' => 'railspress/posts#archive', defaults: {taxonomy: 'author'}

  scope :admin do
    resources :options, controller: 'railspress/options' , as: :admin_options
  end

  get 'test' => 'railspress/pages#test'

  get '*slug' => 'railspress/posts#single', as: :show_page

  # mount Railspress::Engine => "/railspress"

  root 'railspress/pages#index'

end
