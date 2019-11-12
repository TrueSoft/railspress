module Railspress
  class Postmeta < ApplicationRecord
    self.table_name = self.prefix_table_name('postmeta')

    belongs_to :post
  end
end