module Railspress
  require 'railspress/wp_rewrite'
  require 'railspress/taxonomy_lib'

  class GlobalVars
    include Railspress::TaxonomyLib

    attr_accessor :wp_rewrite
    attr_accessor :wp_post_types
    attr_accessor :post_type_meta_caps
    attr_accessor :_wp_post_type_features
    attr_accessor :wp_taxonomies
    attr_accessor :wp_theme_directories
    attr_accessor :_wp_theme_features
    attr_accessor :wp_filter
    attr_accessor :wp_current_filter

    def initialize
      @wp_rewrite = Railspress::WpRewrite.new
      @post_type_meta_caps = {}
      @_wp_theme_features = {}
      @wp_taxonomies = {}
      @wp_filter = {}
      @wp_current_filter = []
    end

    def init
      @wp_rewrite.init

      puts "Initializing Railspress - create_initial_post_types..."
      PostsHelper.create_initial_post_types

      puts "Initializing Railspress - create_initial_taxonomies..."
      create_initial_taxonomies

    end

  end
end