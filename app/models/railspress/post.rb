module Railspress
  class Post < WpPost
    validates :post_title, presence: true

    self.per_page = 10
  end
end