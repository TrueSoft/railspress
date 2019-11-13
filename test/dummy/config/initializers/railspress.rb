Railspress.setup do |config|
  config.ABSPATH = "https://blog.truesoft.ro/"   # Wordpress URL
  config.WPINC =  "wp-includes"
  # config.UPLOADS = "images"
  config.WP_CONTENT_DIR = "https://blog.truesoft.ro/wp-content" # ABSPATH + 'wp-content'
  config.WP_POST_REVISIONS = true

end