module Railspress
  class NavMenu < Taxonomy
    has_many :menuitems, -> { order(:menu_order).where(post_status: 'publish') }, through: :relationships
  end
end