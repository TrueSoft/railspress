module Railspress
  class User < ApplicationRecord
    self.table_name = self.prefix_table_name('users')

    has_many :posts, foreign_key: :post_author
    has_many :metas, class_name: Usermeta.name, foreign_key: :user_id
  end
end