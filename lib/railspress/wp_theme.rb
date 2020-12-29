=begin
 * WP_Theme Class
 *
 * file wp-includes\class-wp-theme.php
=end
class Railspress::WP_Theme

  # Headers for style.css files.
  FILE_HEADERS = {
    Name: 'Theme Name',
    ThemeURI: 'Theme URI',
    Description: 'Description',
    Author: 'Author',
    AuthorURI: 'Author URI',
    Version: 'Version',
    Template: 'Template',
    Status: 'Status',
    Tags: 'Tags',
    TextDomain: 'Text Domain',
    DomainPath: 'Domain Path',
  }

  #	Default themes.
  DEFAULT_THEMES = {
    classic: 'WordPress Classic',
    default: 'WordPress Default',
    twentyten: 'Twenty Ten',
    twentyeleven: 'Twenty Eleven',
    twentytwelve: 'Twenty Twelve',
    twentythirteen: 'Twenty Thirteen',
    twentyfourteen: 'Twenty Fourteen',
    twentyfifteen: 'Twenty Fifteen',
    twentysixteen: 'Twenty Sixteen',
    twentyseventeen: 'Twenty Seventeen',
    twentynineteen: 'Twenty Nineteen',
    twentytwenty: 'Twenty Twenty',
  }
  attr_accessor :theme_root
  attr_accessor :headers
  # The directory name of the theme's files, inside the theme root.
  #
  # In the case of a child theme, this is directory name of the child theme.
  # Otherwise, 'stylesheet' is the same as 'template'.
  attr_accessor :stylesheet

  # The directory name of the theme's files, inside the theme root.
  #
  # In the case of a child theme, this is the directory name of the parent theme.
  # Otherwise, 'template' is the same as 'stylesheet'.
  attr_accessor :template

  def initialize(theme_dir, theme_root, child = nil)
    @headers = {}
    @theme_root = theme_root
    @stylesheet = theme_dir

    theme_file = @stylesheet + '/style.css'

    @headers = Railspress::Functions.get_file_data(@theme_root + '/' + theme_file, FILE_HEADERS, 'theme')
  end

  #  Get a raw, unformatted theme header.
  #
  #  The header is sanitized, but is not translated, and is not marked up for display.
  #  To get a theme header for display, use the display() method.
  #
  #  Use the get_template() method, not the 'Template' header, for finding the template.
  #  The 'Template' header is only good for what was written in the style.css, while
  #  get_template() takes into account where WordPress actually located the theme and
  #  whether it is actually valid.
  #
  #  @param [string] header Theme header. Name, Description, Author, Version, ThemeURI, AuthorURI, Status, Tags.
  #  @return [string|FalseClass] String on success, false on failure.
  def get(header)
    return false if @headers[header].blank?
    sanitize_header(header, @headers[header])
  end

  # Gets a theme header, formatted and translated for display.
  #
  # @param [string] header Theme header. Name, Description, Author, Version, ThemeURI, AuthorURI, Status, Tags.
  # @param [Boolean] markup Optional. Whether to mark up the header. Defaults to true.
  # @param [Boolean] translate Optional. Whether to translate the header. Defaults to true.
  # @return [string|FalseClass] Processed header, false on failure.
  def display(header, markup = true, translate = true)
    value = get(header)
    return false if value == false

    if translate && (value.blank? || !load_textdomain)
      translate = false
    end

    value = translate_header(header, value) if translate
    value = markup_header(header, value, translate) if markup
    value
  end

  private

  #  Sanitize a theme header.
  #
  #  @staticvar array $header_tags
  #  @staticvar array $header_tags_with_a
  #
  #  @param [string] header Theme header. Name, Description, Author, Version, ThemeURI, AuthorURI, Status, Tags.
  #  @param [string] value Value to sanitize.
  #  @return mixed
  def sanitize_header(header, value)
    value
  end

  # Mark up a theme header.
  #
  # @staticvar string $comma
  #
  # @param [string] header Theme header. Name, Description, Author, Version, ThemeURI, AuthorURI, Status, Tags.
  # @param [string] value Value to mark up.
  # @param [string] translate Whether the header has been translated.
  # @return [string] Value, marked up.
  def markup_header(header, value, translate)
    value
  end

  # Translate a theme header.
  #
  # @staticvar array $tags_list
  #
  # @param [string] header Theme header. Name, Description, Author, Version, ThemeURI, AuthorURI, Status, Tags.
  # @param [string] value Value to translate.
  # @return string Translated value.
  def translate_header(header, value)
    value
  end

  public

  # The directory name of the theme's "stylesheet" files, inside the theme root.
  #
  # In the case of a child theme, this is directory name of the child theme.
  # Otherwise, get_stylesheet() is the same as get_template().
  #
  # @return [string] Stylesheet
  def get_stylesheet
    @stylesheet
  end

  # The directory name of the theme's "template" files, inside the theme root.
  #
  # In the case of a child theme, this is the directory name of the parent theme.
  # Otherwise, the get_template() is the same as get_stylesheet().
  #
  # @return string Template
  def get_template
    @template
  end
end