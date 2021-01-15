Rails.application.routes.draw do

  get 'category/:slug' => 'railspress/archive#taxonomy', defaults: {taxonomy: 'category'}
  get 'tag/:slug' => 'railspress/archive#taxonomy', defaults: {taxonomy: 'post_tag'}
  get 'author/:slug' => 'railspress/archive#author', defaults: {taxonomy: 'author'}

  scope :admin do
    resources :options, controller: 'railspress/options' , as: :admin_options
  end

  get 'test' => 'railspress/home#testing_page'

  # get '*slug' => 'railspress/posts#single', as: :show_page

  mount Railspress::Engine => '/'

  root 'railspress/home#index'

end
