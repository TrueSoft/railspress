Railspress.setup do |config|
  config.ABSPATH = "https://blog.truesoft.ro/"   # Wordpress URL
  config.WPINC =  "wp-includes"
  # config.UPLOADS = "images"
  config.WP_CONTENT_DIR = "https://blog.truesoft.ro/wp-content"
  config.WP_CONTENT_URL = "https://blog.truesoft.ro/wp-content"
  config.WP_POST_REVISIONS = true

  config.TS_READONLY_OPTIONS = %w(theme_mods_twentynineteen)
  config.TS_EDITABLE_OPTIONS = %w(my_option other_option with_prefix_*)

  config.posts_permalink_prefix = 'news'

end