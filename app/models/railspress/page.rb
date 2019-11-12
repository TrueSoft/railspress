module Railspress
  class Page < WpPost
    # has_many :metas, class_name: Pagemeta.name, foreign_key: :post_id
    has_many :subpages, class_name: Railspress::Page.name, foreign_key: :post_id

    belongs_to :parent, class_name: Railspress::Page.name, foreign_key: :post_parent

  end
end