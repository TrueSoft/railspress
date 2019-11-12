=begin
 * Theme, template, and stylesheet functions.
 *
 * file wp-includes\theme.php
=end
module Railspress::ThemeHelper

  # Gets a WP_Theme object for a theme.
  #
  # @global array $wp_theme_directories
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
        theme_root = Rails.application.secrets.WP_CONTENT_DIR + '/themes'
      elsif !Railspress::GLOBAL.wp_theme_directories.include?(theme_root)
        theme_root = Rails.application.secrets.WP_CONTENT_DIR + theme_root
      end
    end
    WP_Theme.new( stylesheet, theme_root )
  end

  # Retrieve all theme modifications.
  #
  # @return [array|void] Theme modifications.
  def get_theme_mods
    theme_slug = get_option( 'stylesheet' )
    mods       = get_option( "theme_mods_#{theme_slug}" )
    unless mods
      theme_name = get_option( 'current_theme' )
      unless theme_name
        theme_name = wp_get_theme.get( 'Name' )
      end
      mods = get_option( "mods_#{theme_name}" ) # Deprecated location.
      # if is_admin() && false != mods
      #   update_option( "theme_mods_#{theme_slug}", mods )
      #   delete_option( "mods_#{theme_name}" )
      # end
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

end