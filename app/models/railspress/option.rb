module Railspress
  class Option < ApplicationRecord
    self.table_name = self.prefix_table_name('options')
    self.primary_key = :option_id

    # TODO ch_migr: include PublicActivity::Model

    validates_uniqueness_of :option_name
  end
end