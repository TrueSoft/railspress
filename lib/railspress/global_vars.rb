module Railspress
  class GlobalVars
    attr_accessor :_wp_post_type_features
    attr_accessor :wp_taxonomies
    attr_accessor :wp_rewrite
    attr_accessor :wp_post_types
    attr_accessor :post_type_meta_caps
    attr_accessor :wp_theme_directories
    attr_accessor :wp_filter
    attr_accessor :wp_current_filter

    def initialize
      @post_type_meta_caps = {}
      @wp_rewrite = WpRewrite.new
    end

  end
end