Rails.application.routes.draw do

  get 'news' => 'railspress/home#posts', as: :all_posts

  scope :news do
    get ':slug' => 'railspress/posts#single'
    get 'tag/:slug' => 'railspress/posts#archive', defaults: {taxonomy: 'post_tag'}
    get ':taxonomy/:slug' => 'railspress/posts#archive'
  end

  get 'category/:slug' => 'railspress/archive#taxonomy', defaults: {taxonomy: 'category'}
  get 'tag/:slug' => 'railspress/archive#taxonomy', defaults: {taxonomy: 'post_tag'}
  get 'author/:slug' => 'railspress/archive#author', defaults: {taxonomy: 'author'}

  scope :admin do
    resources :options, controller: 'railspress/options' , as: :admin_options
  end

  get 'test' => 'railspress/pages#test'

  get '*slug' => 'railspress/posts#single', as: :show_page

  # mount Railspress::Engine => "/railspress"

  root 'railspress/home#index'

end
