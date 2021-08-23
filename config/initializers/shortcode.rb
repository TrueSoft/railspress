shortcode = Shortcode.new

shortcode.setup do |config|
  p "Initializing shortcodes..."
  config.block_tags = [:quote, :list]
  config.template_path = "app/views/railspress/shortcode_templates"
  config.templates = [:ts_childpages, :ts_revisions, :ts_customposts]
  config.self_closing_tags = [:ts_childpages, :ts_revisions, :ts_customposts]
end