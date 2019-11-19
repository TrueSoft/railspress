module Railspress
  require 'railspress/global_vars'

  class Engine < ::Rails::Engine
    isolate_namespace Railspress

    ActiveSupport.on_load :action_controller do
      helper Railspress::Engine.helpers
    end

    # Add a load path for this specific Engine
    config.autoload_paths += %W( #{config.root}/lib )
    config.autoload_paths += %W( #{config.root}/app/helpers/railspress )
    config.autoload_paths += %W( #{config.root}/app/models/railspress )

    config.after_initialize do
      puts 'Initializing Railspress - GLOBAL'
      Railspress.GLOBAL.init

      # Register the default theme directory root
      puts 'Initializing Railspress - register_theme_directory...'
      Railspress::ThemeHelper.register_theme_directory('themes') # get_theme_root() does not work

    end
  end

  class << self
    mattr_accessor :ABSPATH
    mattr_accessor :WPINC
    # In WordPress, it can be set in wp-config.php like this: define('UPLOADS', 'images');
    mattr_accessor :UPLOADS
    # WP_CONTENT_DIR = ABSPATH + 'wp-content'
    mattr_accessor :WP_CONTENT_DIR
    # WP_PLUGIN_DIR = WP_CONTENT_DIR . '/plugins'
    # full path, no trailing slash
    mattr_accessor :WP_PLUGIN_DIR

    # WP_CONTENT_URL = get_option('siteurl') + '/wp-content'
    # full url - WP_CONTENT_DIR is defined further up
    mattr_accessor :WP_CONTENT_URL
    # WP_PLUGIN_URL = WP_CONTENT_URL + '/plugins'
    # full url, no trailing slash
    mattr_accessor :WP_PLUGIN_URL

    mattr_accessor :WP_POST_REVISIONS

    # Relative to ABSPATH. For back compat.
    # mattr_accessor :PLUGINDIR "wp-content/plugins"

    mattr_accessor :TS_READONLY_OPTIONS
    mattr_accessor :TS_EDITABLE_OPTIONS
    mattr_accessor :GLOBAL

    # add default values of more config vars here
    self.WPINC = "wp-includes"
    self.UPLOADS = nil # must be nil if the constant is not set in WordPress in wp-config.php
    self.WP_PLUGIN_DIR = "wp-content/plugins"
    self.GLOBAL = Railspress::GlobalVars.new
  end

  # this function maps the vars from your app into your engine
  def self.setup(&block)
    yield self




  end
end
