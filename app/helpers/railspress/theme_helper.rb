=begin
 * Theme, template, and stylesheet functions.
 *
 * file wp-includes\theme.php
=end
module Railspress::ThemeHelper

  # Gets a WP_Theme object for a theme.
  #
  # @param [string] stylesheet Directory name for the theme. Optional. Defaults to current theme.
  # @param [string] theme_root Absolute path of the theme root to look in. Optional. If not specified, get_raw_theme_root()
  #                            is used to calculate the theme root for the $stylesheet provided (or current theme).
  # @return [WP_Theme] Theme object. Be sure to check the object's exists() method if you need to confirm the theme's existence.
  def wp_get_theme(stylesheet = nil, theme_root = nil )
    stylesheet = get_stylesheet() if stylesheet.blank?

    if theme_root.blank?
      theme_root = get_raw_theme_root( stylesheet )
      if false == theme_root
        theme_root = Railspress.WP_CONTENT_DIR + '/themes'
      elsif !Railspress.GLOBAL.wp_theme_directories.include?(theme_root)
        theme_root = Railspress.WP_CONTENT_DIR + theme_root
      end
    end
    Railspress::WP_Theme.new( stylesheet, theme_root )
  end

  # Whether a child theme is in use.
  #
  # @return bool true if a child theme is in use, false otherwise.
  def is_child_theme
    TEMPLATEPATH != STYLESHEETPATH
  end

  # Retrieve name of the current stylesheet.
  #
  # The theme name that the administrator has currently set the front end theme
  # as.
  #
  # For all intents and purposes, the template name and the stylesheet name are
  # going to be the same for most cases.
  #
  # @return string Stylesheet name.
  def get_stylesheet
    # Filters the name of current stylesheet.
    apply_filters('stylesheet', get_option('stylesheet'))
  end

  # Retrieve stylesheet directory path for current theme.
  #
  # @return string Path to current theme directory.
  def get_stylesheet_directory
    stylesheet     = get_stylesheet
    theme_root     = get_theme_root(stylesheet)
    stylesheet_dir = "#{theme_root}/#{stylesheet}"

    # Filters the stylesheet directory path for current theme.
    apply_filters( 'stylesheet_directory', stylesheet_dir, stylesheet, theme_root )
  end

  # Retrieve stylesheet directory URI.
  #
  # @return string
  def get_stylesheet_directory_uri
    stylesheet         = Railspress::PHP.rawurlencode(get_stylesheet).gsub('%2F', '/')
    theme_root_uri     = get_theme_root_uri( stylesheet )
    stylesheet_dir_uri = "#{theme_root_uri}/#{stylesheet}"

    # Filters the stylesheet directory URI.
    apply_filters( 'stylesheet_directory_uri', stylesheet_dir_uri, stylesheet, theme_root_uri )
  end

  # Retrieves the URI of current theme stylesheet.
  #
  # The stylesheet file name is 'style.css' which is appended to the stylesheet directory URI path.
  # See get_stylesheet_directory_uri().
  #
  # @return string
  def get_stylesheet_uri
    stylesheet_dir_uri = get_stylesheet_directory_uri
    stylesheet_uri     = stylesheet_dir_uri + '/style.css'
    # Filters the URI of the current theme stylesheet.
    apply_filters('stylesheet_uri', stylesheet_uri, stylesheet_dir_uri)
  end

  # Retrieve name of the current theme.
  #
  # @return string Template name.
  def get_template
    # Filters the name of the current theme.
    apply_filters('template', get_option('template'))
  end

  # Retrieve current theme directory.
  #
  # @return [string] Template directory path.
  def get_template_directory
    template     = get_template
    theme_root   = get_theme_root(template)
    template_dir = "#{theme_root}/#{template}"

    # Filters the current theme directory path.
    #
    # @param string $template_dir The URI of the current theme directory.
    # @param string $template     Directory name of the current theme.
    # @param string $theme_root   Absolute path to the themes directory.
    apply_filters('template_directory', template_dir, template, theme_root )
  end

  # Retrieve theme directory URI.
  #
  # @return string Template directory URI.
  def get_template_directory_uri
    template = rawurlencode(get_template).gsub('%2F', '/')
    theme_root_uri = get_theme_root_uri(template)
    template_dir_uri = "#{theme_root_uri}/#{template}"

    # Filters the current theme directory URI.
    apply_filters('template_directory_uri', template_dir_uri, template, theme_root_uri)
  end

  # Register a directory that contains themes.
  #
  # @global Railspress.GLOBAL.wp_theme_directories
  #
  # @param [string] directory Either the full filesystem path to a theme folder or a folder within WP_CONTENT_DIR
  # @return bool
  def self.register_theme_directory( directory )
    unless File.exist? directory
      # Try prepending as the theme directory could be relative to the content directory
      directory = Railspress.WP_CONTENT_DIR + '/' + directory unless Railspress.WP_CONTENT_DIR.nil?
      # If this directory does not exist, return and do not register
      # TS_INFO: cannot access the WP dir, so we continue...  return false unless File.exist?(directory)
    end

    Railspress.GLOBAL.wp_theme_directories = [] unless !Railspress.GLOBAL.wp_theme_directories.nil? && Railspress.GLOBAL.wp_theme_directories.is_a(Array)

    untrailed = Railspress::FormattingHelper.untrailingslashit( directory )
    if !untrailed.blank? && !Railspress.GLOBAL.wp_theme_directories.include?(untrailed)
      Railspress.GLOBAL.wp_theme_directories << untrailed
    end
    true
  end

  # Retrieve path to themes directory.
  #
  # Does not have trailing slash.
  #
  # @param [string] stylesheet_or_template The stylesheet or template name of the theme
  # @return string Theme path.
  def get_theme_root(stylesheet_or_template = false )
    if stylesheet_or_template && theme_root = get_raw_theme_root(stylesheet_or_template)
      # Always prepend WP_CONTENT_DIR unless the root currently registered as a theme directory.
      # This gives relative theme roots the benefit of the doubt when things go haywire.
      theme_root = Railspress.WP_CONTENT_DIR + theme_root unless Railspress.GLOBAL.wp_theme_directories.include?(theme_root)
    else
      theme_root = Railspress.WP_CONTENT_DIR + '/themes'
    end

    # Filters the absolute path to the themes directory.
    apply_filters( 'theme_root', theme_root )
  end

  # Retrieve URI for themes directory.
  #
  # Does not have trailing slash.
  #
  # @param [string] stylesheet_or_template Optional. The stylesheet or template name of the theme.
  #                                        Default is to leverage the main theme root.
  # @param [string] theme_root             Optional. The theme root for which calculations will be based, preventing
  #                                        the need for a get_raw_theme_root() call.
  # @return [string] Themes URI.
  def get_theme_root_uri( stylesheet_or_template = false, theme_root = false )
    theme_root = get_raw_theme_root(stylesheet_or_template) if  stylesheet_or_template && ! theme_root

    if ( stylesheet_or_template && theme_root )
      if Railspress.GLOBAL.wp_theme_directories.nil?
        p "get_theme_root_uri(#{stylesheet_or_template}, #{theme_root})"
      end
      if Railspress.GLOBAL.wp_theme_directories.include?(theme_root)
        # Absolute path. Make an educated guess. YMMV -- but note the filter below.
        if theme_root.start_with?(Railspress.WP_CONTENT_DIR)
          theme_root_uri = content_url( theme_root.gsub( WP_CONTENT_DIR, '') )
        elsif theme_root.start_with?(Railspress.ABSPATH)
          theme_root_uri = site_url(theme_root.gsub(Railspress.ABSPATH, ''))
        elsif theme_root.start_with?(Railspress.WP_PLUGIN_DIR) || theme_root.start_with?(Railspress.WPMU_PLUGIN_DIR)
          theme_root_uri = plugins_url( basename( theme_root ), theme_root )
        else
          theme_root_uri = theme_root
        end
      else
        theme_root_uri = content_url( theme_root )
      end
    else
      theme_root_uri = content_url( 'themes' )
    end

    # Filters the URI for themes directory.
    apply_filters( 'theme_root_uri', theme_root_uri, get_option( 'siteurl' ), stylesheet_or_template )
  end


  # Get the raw theme root relative to the content directory with no filters applied.
  #
  # @param [string] stylesheet_or_template The stylesheet or template name of the theme
  # @param [bool]   skip_cache             Optional. Whether to skip the cache.
  #                                        Defaults to false, meaning the cache is used.
  # @return [string] Theme root
  def get_raw_theme_root(stylesheet_or_template, skip_cache = false)
    if !Railspress.GLOBAL.wp_theme_directories.kind_of?(Array) || Railspress.GLOBAL.wp_theme_directories.size <= 1
      return '/themes'
    end

    theme_root = false

    # If requesting the root for the current theme, consult options to avoid calling get_theme_roots()
    if !skip_cache
      if get_option( 'stylesheet' ) == stylesheet_or_template
        theme_root = get_option( 'stylesheet_root' )
      elsif get_option( 'template' ) == stylesheet_or_template
        theme_root = get_option( 'template_root' )
      end
    end

    if theme_root.blank?
      theme_roots = get_theme_roots
      if !theme_roots[ stylesheet_or_template ].blank?
        theme_root = theme_roots[ stylesheet_or_template ]
      end
    end

    theme_root
  end

  # Display localized stylesheet link element.
  def locale_stylesheet
    stylesheet = get_locale_stylesheet_uri
    return if stylesheet.blank?

    '<link rel="stylesheet" href="' + stylesheet + '" type="text/css" media="screen" />'
  end

  # Switches the theme.
  #
  # Accepts one argument: stylesheet of the theme. It also accepts an additional function signature
  # of two arguments: template then $stylesheet. This is for backward compatibility.
  #
  # @param [string] stylesheet Stylesheet name
  def switch_theme(stylesheet)
    # TS_INFO: Manage themes not implemented
  end

  # Checks that current theme files 'index.php' and 'style.css' exists.
  #
  # Does not initially check the default theme, which is the fallback and should always exist.
  # But if it doesn't exist, it'll fall back to the latest core default theme that does exist.
  # Will switch theme to the fallback theme if current theme does not validate.
  #
  # You can use the {@see 'validate_current_theme'} filter to return false to
  # disable this functionality.
  #
  # @see WP_DEFAULT_THEME
  #
  # @return bool
  def validate_current_theme
    # TS_INFO: Manage themes not implemented
  end

  # Retrieve all theme modifications.
  #
  # @return [array|void] Theme modifications.
  def get_theme_mods
    theme_slug = get_option( 'stylesheet' )
    mods       = get_option( "theme_mods_#{theme_slug}" )
    if mods
      theme_name = get_option( 'current_theme' )
      unless theme_name
        theme_name = wp_get_theme.get( 'Name' )
      end
      # mods = get_option( "mods_#{theme_name}" ) # Deprecated location.
      # if is_admin() && false != mods
      #   update_option( "theme_mods_#{theme_slug}", mods )
      #   delete_option( "mods_#{theme_name}" )
      # end
    else
      mods = {}
    end
    mods
  end

  # Retrieve theme modification value for the current theme.
  #
  # If the modification name does not exist, then the $default will be passed
  # through {@link https://secure.php.net/sprintf sprintf()} PHP function with the first
  # string the template directory URI and the second string the stylesheet
  # directory URI.
  #
  # @since 2.1.0
  #
  # @param [string]      name    Theme modification name.
  # @param [bool|string] default
  # @return mixed
  def get_theme_mod(name, default = false )
    mods = get_theme_mods

    unless mods[name].blank?
      # Filters the theme modification, or 'theme_mod', value.
      return apply_filters( "theme_mod_{#{name}}", mods[name])
    end

    if default.is_a? String
      default = sprintf( default, get_template_directory_uri, get_stylesheet_directory_uri )
    end

    # This filter is documented in wp-includes/theme.php
    apply_filters( "theme_mod_{#{name}}", default )
  end

  # Update theme modification value for the current theme.
  #
  # @param [string] name  Theme modification name.
  # @param [mixed]  value Theme modification value.
  def set_theme_mod(name, value)
    # TS_INFO: Manage themes not implemented
  end

  # Retrieves the custom header text color in 3- or 6-digit hexadecimal form.
  #
  # @return string Header text color in 3- or 6-digit hexadecimal form (minus the hash symbol).
  def get_header_textcolor
    get_theme_mod('header_textcolor', get_theme_support( 'custom-header', 'default-text-color' ))
  end

  # Displays the custom header text color in 3- or 6-digit hexadecimal form (minus the hash symbol).
  def header_textcolor
    get_header_textcolor
  end

  # Whether to display the header text.
  #
  # @return bool
  def display_header_text
    return false unless current_theme_supports('custom-header', 'header-text')

    text_color = get_theme_mod( 'header_textcolor', get_theme_support( 'custom-header', 'default-text-color' ) )
    'blank' != text_color
  end

  # Gets the theme support arguments passed when registering that support
  #
  # @global array $_wp_theme_features
  #
  # @param [string] feature The feature to check.
  # @return mixed The array of extra arguments or the value for the registered feature.
  def get_theme_support(feature, *args)
    # TS_INFO: Customizer not implemented
    false
  end

  # Allows a theme to de-register its support of a certain feature
  #
  # Should be called in the theme's functions.php file. Generally would
  # be used for child themes to override support from the parent theme.
  #
  # @see add_theme_support()
  # @param [string] feature The feature being removed.
  # @return [bool|void] Whether feature was removed.
  def remove_theme_support(feature)
    # TS_INFO: Customizer not implemented
    false
  end

  # Checks a theme's support for a given feature.
  #
  # @param [string] feature The feature being checked.
  # @return [bool] True if the current theme supports the feature, false otherwise.
  def current_theme_supports( feature, *args )
    return current_theme_supports('custom-header', 'uploads') if feature == 'custom-header-uploads'

    return false if !isset( Railspress.GLOBAL._wp_theme_features[ feature ] )

    # If no args passed then no extra checks need be performed
    return true if args.blank?

    case feature
    when 'post-thumbnails'
      # post-thumbnails can be registered for only certain content/post types by passing
      # an array of types to add_theme_support(). If no array was passed, then
      # any type is accepted
      return true if Railspress.GLOBAL._wp_theme_features[ feature ] == true # Registered for all types

      content_type = args[0]
      return Railspress.GLOBAL._wp_theme_features[ feature ][0].include?(content_type)

    when 'html5', 'post-formats'
      # specific post formats can be registered by passing an array of types to
      # add_theme_support()

      # Specific areas of HTML5 support *must* be passed via an array to add_theme_support()
      type = args[0]
      return Railspress.GLOBAL._wp_theme_features[ feature ][0].include?(type)

    when 'custom-logo', 'custom-header', 'custom-background'
      # Specific capabilities can be registered by passing an array to add_theme_support().
      return ( !Railspress.GLOBAL._wp_theme_features[feature][0][args[0]].blank? && Railspress.GLOBAL._wp_theme_features[feature][0][args[0]] )
    end

    # Filters whether the current theme supports a specific feature.
    #
    # The dynamic portion of the hook name, `$feature`, refers to the specific theme
    # feature. Possible values include 'post-formats', 'post-thumbnails', 'custom-background',
    # 'custom-header', 'menus', 'automatic-feed-links', 'html5',
    # 'starter-content', and 'customize-selective-refresh-widgets'.
    #
    # @param bool   true     Whether the current theme supports the given feature. Default true.
    # @param array  $args    Array of arguments for the feature.
    # @param string $feature The theme feature.
    apply_filters( "current_theme_supports-#{feature}", true, args, _wp_theme_features[ feature ] )
  end

 # Whether the site is being previewed in the Customizer.
 #
 # @return bool True if the site is being previewed in the Customizer, false otherwise.
 def is_customize_preview
   # TS_INFO: Customizer not implemented
   false
 end

end