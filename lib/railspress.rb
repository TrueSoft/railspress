require "railspress/engine"

module Railspress

  include ActiveSupport::Configurable

#  config_accessor :post_type_meta_caps, :wp_rewrite, :multi_language

  config_accessor :multi_language

#  self.post_type_meta_caps = {}

 # self.wp_rewrite = Railspress::WpRewrite.new

  self.multi_language = false


end
