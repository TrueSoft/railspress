require "railspress/engine"

module Railspress

  include ActiveSupport::Configurable

#  config_accessor :post_type_meta_caps, :wp_rewrite, :multi_language

  config_accessor :multi_language, :links_to_wp, :generate_breadcrumb, :posts_permalink_prefix, :pages_permalink_prefix

#  self.post_type_meta_caps = {}

 # self.wp_rewrite = Railspress::WpRewrite.new

  self.multi_language = false
  self.links_to_wp = false
  self.generate_breadcrumb = false

  # see permalink_structure/get_post_type_archive_link('post')
  self.posts_permalink_prefix = nil

  self.pages_permalink_prefix = nil

end
