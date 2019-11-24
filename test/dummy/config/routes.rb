Rails.application.routes.draw do

  get 'news' => 'railspress/posts#index', as: :all_posts
  get 'news/:year' => 'railspress/posts#by_year', constraints: {year: /20[12]\d/}, as: :news_of_year
  get 'news/:year/:month' => 'railspress/posts#by_month', constraints: {year: /20[12]\d/, month: /(0?\d)|10|11|12/}
  scope :news do
    get ':slug' => 'railspress/posts#show'
    get 'tag/:slug' => 'railspress/posts#tag'
    get 'category/:slug' => 'railspress/posts#category'
  end

  get 'page/*slug' => 'railspress/pages#show', as: :show_page

  scope :admin do
    resources :options, controller: 'railspress/options' , as: :admin_options
  end

  get 'test' => 'railspress/pages#test'

  # mount Railspress::Engine => "/railspress"

  root 'railspress/pages#home'

end
