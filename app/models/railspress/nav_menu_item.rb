module Railspress
  class NavMenuItem < WpPost
    include Railspress::MetaHelper
    include Railspress::PostsHelper

    attr_accessor :current
    attr_accessor :db_id

    attr_accessor :menu_item_parent
    attr_accessor :object_id_ # renamed because in ruby there is one in Object class
    attr_accessor :object
    attr_accessor :type

    attr_accessor :type_label
    attr_accessor :title
    attr_accessor :url
    attr_accessor :target
    attr_accessor :attr_title
    attr_accessor :description
    attr_accessor :xfn
    attr_accessor :classes
    attr_accessor :_invalid

  end
end