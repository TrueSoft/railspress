module Railspress
  class Attachmentmeta < ApplicationRecord
    self.table_name = self.prefix_table_name('postmeta')

    belongs_to :attachment, foreign_key: :post_id, class_name: Railspress::Attachment.name
  end
end