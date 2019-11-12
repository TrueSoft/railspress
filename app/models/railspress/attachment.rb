module Railspress
  class Attachment < WpPost
    has_many :metas, class_name: Railspress::Attachmentmeta.name, foreign_key: :post_id
  end
end