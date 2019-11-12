Rails.application.routes.draw do

  # get 'news', to: 'contact#index'

  get 'news' => 'railspress/posts#index'
  get 'news/:year' => 'railspress/posts#by_year', constraints: {year: /20[12]\d/}, as: :news_of_year
  get 'news/:year/:month' => 'railspress/posts#by_month', constraints: {year: /20[12]\d/, month: /(0?\d)|10|11|12/}
  get 'news/:slug' => 'railspress/posts#show' # , as: :show_post
  get 'news/show/:id' => 'railspress/posts#show_id', constraints: {id: /\d+/}
  get 'news/tag/:slug' => 'railspress/posts#tag'

  get 'page/*slug' => 'railspress/pages#show'

  mount Railspress::Engine => "/railspress"

  root 'railspress/pages#home'

end
