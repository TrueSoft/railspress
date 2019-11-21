require 'railspress/plugin'
=begin
 * Main WordPress Formatting API.
 *
 * Handles many functions for formatting output.
 *
 * file wp-includes\formatting.php
=end
module Railspress::FormattingHelper

  # Converts a number of special characters into their HTML entities.
  #
  # Specifically deals with: &, <, >, ", and '.
  #
  # quote_style can be set to ENT_COMPAT to encode " to
  # &quot;, or ENT_QUOTES to do both. Default is ENT_NOQUOTES where no quotes are encoded.
  #
  # @param [String]     string         The text which is to be encoded.
  # @param [int|string] quote_style    Optional. Converts double quotes if set to ENT_COMPAT,
  #                                     both single and double if set to ENT_QUOTES or none if set to ENT_NOQUOTES.
  #                                     Also compatible with old values; converting single quotes if set to 'single',
  #                                     double if set to 'double' or both if otherwise set.
  #                                     Default is ENT_NOQUOTES.
  # @param [String]     charset         Optional. The character encoding of the string. Default is false.
  # @param [bool]       double_encode  Optional. Whether to encode existing html entities. Default is false.
  # @return string The encoded text with HTML entities.
  def _wp_specialchars(string, quote_style = :ENT_NOQUOTES, charset = false, double_encode = false)
    string = string.to_s

    return '' if string == ''

    # Don't bother if there are no specialchars - saves some processing
    return string unless string =~ /[&<>"']/

  	# Account for the previous behaviour of the function when the $quote_style is not an accepted value
    if quote_style.blank?
      quote_style = :ENT_NOQUOTES
    elsif  ![0, 2, 3, 'single', 'double' ].include? quote_style
      quote_style = :ENT_QUOTES
    end

    # TODO continue implement function _wp_specialchars
	 # Store the site charset as a static to avoid multiple calls to wp_load_alloptions()
	 unless charset
	 	# static $_charset = null;
	# 	if ( ! isset( $_charset ) ) {
	# 		$alloptions = wp_load_alloptions();
	# 		$_charset   = isset( $alloptions['blog_charset'] ) ? $alloptions['blog_charset'] : '';
	# 	}
	# 	$charset = $_charset;
    charset = get_option('blog_charset')
	 end

  charset = 'UTF-8' if ['utf8', 'utf-8', 'UTF8'].include?(charset)

	_quote_style = quote_style

	if quote_style == 'double'
		quote_style  = :ENT_COMPAT
		_quote_style = :ENT_COMPAT
	 elsif quote_style == 'single'
		quote_style = :ENT_NOQUOTES
	end

	unless double_encode
		# Guarantee every &entity; is valid, convert &garbage; into &amp;garbage;
		# This is required for PHP < 5.4.0 because ENT_HTML401 flag is unavailable.
		string = wp_kses_normalize_entities(string)
	end

    string = h(string)
	# TODO string = @htmlspecialchars( $string, $quote_style, $charset, $double_encode )

	# Back-compat.
	if 'single' == _quote_style
		string = string.gsub("'", '&#039;')
  end

  string
  end

  # Sanitizes a string key.
  #
  # Keys are used as internal identifiers. Lowercase alphanumeric characters, dashes and underscores are allowed.
  #
  # @param [string] key String key
  # @return [string] Sanitized key
  def self.sanitize_key(key)
	  raw_key = key
  	key.downcase!
  	key.gsub! /[^a-z0-9_\-]/, ''

	  # Filters a sanitized key string.
    Railspress::Plugin.apply_filters('sanitize_key', key, raw_key)
  end

  # Sanitizes a title, or returns a fallback title.
  #
  # Specifically, HTML and PHP tags are stripped. Further actions can be added
  # via the plugin API. If $title is empty and $fallback_title is set, the latter
  # will be used.
  #
  # @param [string] title          The string to be sanitized.
  # @param [string] fallback_title Optional. A title to use if $title is empty.
  # @param [string] context        Optional. The operation for which the string is sanitized
  # @return [string] The sanitized string.
  def sanitize_title(title, fallback_title = '', context = 'save' )
    raw_title = title

    title = remove_accents( title ) if 'save' == context

    # Filters a sanitized title string.
    #
    # @param string $title     Sanitized title.
    # @param string $raw_title The title prior to sanitization.
    # @param string $context   The context for which the title is being sanitized.
    title = apply_filters( 'sanitize_title', title, raw_title, context )

    title = fallback_title if ( '' == title || false == title )

    title
  end

  # Sanitizes a title with the 'query' context.
  #
  # Used for querying the database for a value from URL.
  #
  # @param [string] title The string to be sanitized.
  # @return [string] The sanitized string.
  def sanitize_title_for_query( title )
    sanitize_title( title, '', 'query' )
  end

  # Sanitizes a title, replacing whitespace and a few other characters with dashes.
  #
  # Limits the output to alphanumeric characters, underscore (_) and dash (-).
  # Whitespace becomes a dash.
  #
  # @param [string] title     The title to be sanitized.
  # @param [string] raw_title Optional. Not used.
  # @param [string] context   Optional. The operation for which the string is sanitized.
  # @return [string] The sanitized title.
  def sanitize_title_with_dashes(title, raw_title = '', context = 'display')
    # TODO title = strip_tags(title)
    # Preserve escaped octets.
    # TODO title = title.gsub( '|%([a-fA-F0-9][a-fA-F0-9])|', '---$1---' )
    # Remove percent signs that are not part of an octet.
    title = title.gsub('%', '')
    # Restore octets.
    # TODO title = preg_replace( '|---([a-fA-F0-9][a-fA-F0-9])---|', '%$1', $title )

    # if seems_utf8(title)
    #   #		title = mb_strtolower( title, 'UTF-8' ) if ( function_exists( 'mb_strtolower' ) )
    #   title = utf8_uri_encode(title, 200)
    # end

    title.downcase!

    if 'save' == context
      # Convert nbsp, ndash and mdash to hyphens
      title.gsub!('%c2%a0', '-')
      title.gsub!('%e2%80%93', '-')
      title.gsub!('%e2%80%94', '-')
      # Convert nbsp, ndash and mdash HTML entities to hyphens
      title.gsub!('&nbsp;', '-')
      title.gsub!('&#160;', '-')
      title.gsub!('&ndash;', '-')
      title.gsub!('&#8211;', '-')
      title.gsub!('&mdash;', '-')
      title.gsub!('&#8212;', '-')
      # Convert forward slash to hyphen
      title.gsub!('/', '-')

      # Strip these characters entirely
      # soft hyphens
      title.gsub!('%c2%ad', '')
      # iexcl and iquest
      title.gsub!('%c2%a1', '')
      title.gsub!('%c2%bf', '')
      # angle quotes
      title.gsub!('%c2%ab', '')
      title.gsub!('%c2%bb', '')
      title.gsub!('%e2%80%b9', '')
      title.gsub!('%e2%80%ba', '')
      # curly quotes
      title.gsub!('%e2%80%98', '')
      title.gsub!('%e2%80%99', '')
      title.gsub!('%e2%80%9c', '')
      title.gsub!('%e2%80%9d', '')
      title.gsub!('%e2%80%9a', '')
      title.gsub!('%e2%80%9b', '')
      title.gsub!('%e2%80%9e', '')
      title.gsub!('%e2%80%9f', '')
      # copy, reg, deg, hellip and trade
      title.gsub!('%c2%a9', '')
      title.gsub!('%c2%ae', '')
      title.gsub!('%c2%b0', '')
      title.gsub!('%e2%80%a6', '')
      title.gsub!('%e2%84%a2', '')
      # acute accents
      title.gsub!('%c2%b4', '')
      title.gsub!('%cb%8a', '')
      title.gsub!('%cc%81', '')
      title.gsub!('%cd%81', '')
      # grave accent, macron, caron
      title.gsub!('%cc%80', '')
      title.gsub!('%cc%84', '')
      title.gsub!('%cc%8c', '')

      # Convert times to x
      title.gsub!('%c3%97', 'x')
    end

    title.gsub!(/&.+?;/, '') # kill entities
    title.gsub!('.', '-')

    title.gsub!(/[^%a-z0-9 _-]/, '')
    title.gsub!(/\s+/, '-')
    title.gsub!('|-+|', '-')
    title.gsub!(/^-+/, '')
    title.gsub!(/-+$/, '')

    title
  end

  # Sanitizes an HTML classname to ensure it only contains valid characters.
  #
  # Strips the string down to A-Z,a-z,0-9,_,-. If this results in an empty
  # string then it will return the alternative value supplied.
  #
  # @to do Expand to support the full range of CDATA that a class attribute can contain.
  #
  # @param [string] clazz    The classname to be sanitized
  # @param [string] fallback Optional. The value to return if the sanitization ends up as an empty string.
  # 	Defaults to an empty string.
  # @return string The sanitized value
  def sanitize_html_class(clazz, fallback = '' )
    # Strip out any % encoded octets
    sanitized = clazz.gsub( /%[a-fA-F0-9][a-fA-F0-9]/, '' )

    # Limit to A-Z,a-z,0-9,_,-
    sanitized = sanitized.gsub( /[^A-Za-z0-9_-]/, '' )

    return sanitize_html_class( fallback ) if (sanitized.blank? && fallback )

    # Filters a sanitized HTML class string.
    #
    # @param string $sanitized The sanitized HTML class.
    # @param string $class     HTML class before sanitization.
    # @param string $fallback  The fallback string.
    apply_filters( 'sanitize_html_class', sanitized, clazz, fallback )
  end

  # Acts on text which is about to be edited.
  #
  # The content is run through esc_textarea(), which uses htmlspecialchars()
  # to convert special characters to HTML entities. If `$richedit` is set to true,
  # it is simply a holder for the {@see 'format_to_edit'} filter.
  #
  # @param [String] content   The text about to be edited.
  # @param [bool]   rich_text Optional. Whether `$content` should be considered rich text,
  #                           in which case it would not be passed through esc_textarea().
  #                           Default false.
  # @return string The text after the filter (and possibly htmlspecialchars()) has been run.
  def format_to_edit(content, rich_text = false)
	 # Filters the text to be formatted for editing.
   content = apply_filters('format_to_edit', content)
   content = esc_textarea(content) unless rich_text
   content
   end

  # Checks for invalid UTF8 in a string.
  #
  # @param [String]  string The text which is to be checked.
  # @param [bool]    strip Optional. Whether to attempt to strip out invalid UTF8. Default is false.
  # @return [String] The checked text.
  def wp_check_invalid_utf8(string, strip = false)
    string = string.to_s

    return '' if string == ''

    # Store the site charset as a static to avoid multiple calls to get_option()
    is_utf8 = nil

    if is_utf8.nil?
      is_utf8 = ['utf8', 'utf-8', 'UTF8', 'UTF-8'].include?(get_option('blog_charset'))
    end
    return string unless is_utf8

    # Check for support for utf8 in the installed PCRE library once and store the result in a static
    utf8_pcre = nil
    if utf8_pcre.nil?
      utf8_pcre = 'a'.match(/^./u)
    end
    # We can't demand utf8 in the PCRE installation, so just return the string in those cases
    return string unless utf8_pcre.nil?

    # preg_match fails when it encounters invalid UTF8 in $string
    return string unless string.match(/^./us).nil?

    # TODO continue implement function wp_check_invalid_utf8
    # # Attempt to strip the bad chars if requested (not recommended)
    # if ( strip && function_exists( 'iconv' ) )
    #   return iconv( 'utf-8', 'utf-8', string )
    # end
    #
	  ''
  end

  # Generates an excerpt from the content, if needed.
  #
  # The excerpt word amount will be 55 words and if the amount is greater than
  # that, then the string ' [&hellip;]' will be appended to the excerpt. If the string
  # is less than 55 words, then the content will be returned as is.
  #
  # The 55 word limit can be modified by plugins/themes using the {@see 'excerpt_length'} filter
  # The ' [&hellip;]' string can be modified by plugins/themes using the {@see 'excerpt_more'} filter
  #
  # @param [String] text Optional. The excerpt. If set to empty, an excerpt is generated.
  # @param [WP_Post|object|int] post Optional. WP_Post instance or Post ID/object. Default is null.
  # @return string The excerpt.
  def wp_trim_excerpt(text = '', post = nil)
    raw_excerpt = text
    if text.empty?
      post = get_post(post) # TODO
      text = post.post_content # text = get_the_content('', false, post) # TODO function get_the_content from post-template.php

      text = strip_shortcodes(text)
      # text = excerpt_remove_blocks(text) # TODO function excerpt_remove_blocks from blocks.php

      # This filter is documented in wp-includes/post-template.php
      text = apply_filters('the_content', text)
      text = text.gsub(']]>', ']]&gt;')

      # Filters the number of words in an excerpt.
      excerpt_length = apply_filters('excerpt_length', 55)

      # Filters the string in the "more" link displayed after a trimmed excerpt.
      excerpt_more = apply_filters('excerpt_more', ' ' + '[&hellip;]')
      text = wp_trim_words(text, excerpt_length, excerpt_more)
    end
    # Filters the trimmed excerpt string.
    apply_filters('wp_trim_excerpt', text, raw_excerpt)
  end

  def get_post_excerpt(post)
    text = post.post_content
    text = strip_shortcodes(text)

    # This filter is documented in wp-includes/post-template.php
    text = apply_filters('the_content', text)
    text = text.gsub(']]>', ']]&gt;')

    # Filters the number of words in an excerpt.
    excerpt_length = apply_filters('excerpt_length', 55)

    # Filters the string in the "more" link displayed after a trimmed excerpt.
    # @param [string] more_string The string shown within the more link.
    excerpt_more = apply_filters('excerpt_more', ' ' + '[&hellip;]')
    text = wp_trim_words(text, excerpt_length, excerpt_more)
  end

  mattr_accessor :trailingslashit, :untrailingslashit

  # Appends a trailing slash.
  #
  # Will remove trailing forward and backslashes if it exists already before adding
  # a trailing forward slash. This prevents double slashing a string or path.
  #
  # The primary use of this is for paths and thus should be used for paths. It is
  # not restricted to paths and offers no specific path support.
  #
  # @param string string What to add the trailing slash to.
  # @return String with trailing slash added.
  def trailingslashit(string)
    untrailingslashit(string) + '/'
  end

  # Removes trailing forward slashes and backslashes if they exist.
  #
  # The primary use of this is for paths and thus should be used for paths. It is
  # not restricted to paths and offers no specific path support.
  #
  # @param [string] string What to remove the trailing slashes from.
  # @return String without the trailing slashes.
  def untrailingslashit(string)
    string.gsub(/[\/\\]+$/, '')
  end

  def self.untrailingslashit(string)
    string.gsub(/[\/\\]+$/, '')
  end

  # Trims text to a certain number of words.
  #
  # @param [String] text      Text to trim.
  # @param [Integer] num_words Number of words. Default 55.
  # @param [String] more      Optional. What to append if text needs to be trimmed. Default '&hellip;'.
  # @return string Trimmed text.
  def wp_trim_words(text, num_words = 55, more = nil)
    if more.nil?
      more = '&hellip;'
    end

    original_text = text
    text = wp_strip_all_tags(text)

    if false # no asian...
    else
      words_array = text.split(/[\n\r\t ]+/, num_words + 1)
      sep = ' '
    end

    if words_array.length > num_words
      words_array.pop
      text = words_array.join(sep)
      text = text + more
    else
      text = words_array.join(sep)
    end

    # Filters the text content after words have been trimmed.
    apply_filters('wp_trim_words', text, num_words, more, original_text)
  end

  # Escapes data for use in a MySQL query.
  #
  # Usually you should prepare queries using wpdb::prepare().
  # Sometimes, spot-escaping is required or useful. One example
  # is preparing an array for use in an IN clause.
  #
  # NOTE: Since 4.8.3, '%' characters will be replaced with a placeholder string,
  # this prevents certain SQLi attacks from taking place. This change in behaviour
  # may cause issues for code that expects the return value of esc_sql() to be useable
  # for other purposes.
  #
  # @global wpdb $wpdb WordPress database abstraction object.
  #
  # @param [string|array] $data Unescaped data
  # @return [string|array] Escaped data
  def esc_sql(data )
    # global $wpdb;
    $wpdb._escape(data)
  end

  # Checks and cleans a URL.
  #
  # A number of characters are removed from the URL. If the URL is for displaying
  # (the default behaviour) ampersands are also replaced. The {@see 'clean_url'} filter
  # is applied to the returned cleaned URL.
  #
  # @param [string] url       The URL to be cleaned.
  # @param [array]  protocols Optional. An array of acceptable protocols.
  #                           Defaults to return value of wp_allowed_protocols()
  # @param [string] _context  Private. Use esc_url_raw() for database usage.
  # @return [string] The cleaned $url after the {@see 'clean_url'} filter is applied.
  def esc_url(url, protocols = nil, _context = 'display')
    original_url = url

    return url if url == ''

    url = url.gsub(' ', '%20')
    url = url.gsub(/[^a-z0-9\-~+_.?#=!&;,\/:%@$|*'()\[\]\\x80-\\xff]/i, '')

    return url if url == ''

    if url.downcase.include? 'mailto:'
      strip = array( '%0d', '%0a', '%0D', '%0A' )
      url   = _deep_replace(strip, url)
    end

    url = url.gsub(';//', '://')
    # If the URL doesn't appear to contain a scheme, we
    # presume it needs http:// prepended (unless a relative
    # link starting with /, # or ? or a php file).
    if  !url.include?(':') && !['/', '#', '?'].include?(url[0]) && !(url =~ /^[a-z0-9-]+?\.php/i)
        url = 'http://' + url
    end

    # Replace ampersands and single quotes only when displaying.
    if 'display' == _context
      url = wp_kses_normalize_entities(url)
      url = url.gsub( '&amp;', '&#038;')
      url = url.gsub( "'", '&#039;')
    end

    if ( url.include?('[') || url.include?(']') )

      parsed = wp_parse_url(url)
      front  = ''

    if !parsed['scheme'].nil?
        front += parsed['scheme'] + '://'
     elsif  '/' == url[0]
      front += '//'
    end

    if !parsed['user'].nil?
        front += parsed['user']
    end

    if !parsed['pass'].nil?
        front += ':' + parsed['pass']
    end

    if !parsed['user'].nil? || !parsed['pass'].nil?
        front += '@'
    end

    if !parsed['host'].nil?
       front += parsed['host']
    end

    if !parsed['port'].nil?
        $front += ':' + parsed['port']
    end

    end_dirty = url.gsub(front, '')
    end_clean = end_dirty.gsub('[', '%5B').gsub(']', '%5D')
    url       = url.gsub(end_dirty, end_clean)

    end

    if '/' == url[0]
      good_protocol_url = url
    else
      protocols = wp_allowed_protocols unless protocols.is_a?(Array)
      good_protocol_url = wp_kses_bad_protocol(url, protocols)
      if good_protocol_url.downcase != url.downcase
        return ''
      end
    end

    # Filters a string cleaned and escaped for output as a URL.
    apply_filters('clean_url', good_protocol_url, original_url, _context )
  end

  # Performs esc_url() for database usage.
  #
  # @param [string] url       The URL to be cleaned.
  # @param [array]  protocols An array of acceptable protocols.
  # @return string The cleaned URL.
  def esc_url_raw(url, protocols = nil)
    esc_url(url, protocols, 'db')
  end

  # Escaping for HTML blocks.
  def esc_html(text)
  	safe_text = wp_check_invalid_utf8(text)
  	safe_text = _wp_specialchars(safe_text, :ENT_QUOTES)
  	# Filters a string cleaned and escaped for output in HTML.
  	apply_filters('esc_html', safe_text, text)
  end

  # Escaping for HTML attributes.
  def esc_attr(text)
	  safe_text = wp_check_invalid_utf8( text )
	  safe_text = _wp_specialchars( safe_text, :ENT_QUOTES )
    # Filters a string cleaned and escaped for output in an HTML attribute.
    # Text passed to esc_attr() is stripped of invalid or special characters  before output.
    apply_filters('attribute_escape', safe_text, text )
  end

  # Escaping for textarea values.
  def esc_textarea(text)
	  safe_text = CGI.escapeHTML text #, ENT_QUOTES, get_option( 'blog_charset' )
	  # Filters a string cleaned and escaped for output in a textarea element.
    apply_filters('esc_textarea', safe_text, text)
  end

  # Parses a string into variables to be stored in an array.
  #
  # @param [string] string The string to be parsed.
  # @param [array]  array  Variables will be stored in this array.
  def wp_parse_str(string, array = nil)
    require 'addressable/uri'
    array = Addressable::URI.parse(string)
    # TODO if ( get_magic_quotes_gpc() ) {
    #     $array = stripslashes_deep( array );
    # }
    # Filters the array of variables derived from a parsed string.
    Railspress::Plugin.apply_filters('wp_parse_str', array)
  end

  module_function :wp_parse_str

  # Properly strip all HTML tags including script and style
  #
  # This differs from strip_tags() because it removes the contents of
  # the `<script>` and `<style>` tags. E.g. `strip_tags( '<script>something</script>' )`
  # will return 'something'. wp_strip_all_tags will return ''
  #
  # @param [String] string        String containing HTML tags
  # @param [bool]   remove_breaks Optional. Whether to remove left over line breaks and white space chars
  # @return [string] The processed string.
  def wp_strip_all_tags(string, remove_breaks = false)
    string = string.gsub(/<(script|style)[^>]*?>.*?<\/\\1>/, '')
    string = strip_tags(string)

    if remove_breaks
      string = string.gsub(/[\r\n\t ]+/, ' ')
    end
    string.strip
  end

  # Sanitizes a string from user input or from the database.
  #
  # - Checks for invalid UTF-8,
  # - Converts single `<` characters to entities
  # - Strips all tags
  # - Removes line breaks, tabs, and extra whitespace
  # - Strips octets
  #
  # @see sanitize_textarea_field()
  # @see wp_check_invalid_utf8()
  # @see wp_strip_all_tags()
  #
  # @param [string] str String to sanitize.
  # @return string Sanitized string.
  def sanitize_text_field(str)
    filtered = _sanitize_text_fields(str, false)

    # Filters a sanitized text field string.
    apply_filters( 'sanitize_text_field', filtered, str)
  end

  # Sanitizes a multiline string from user input or from the database.
  #
  # The function is like sanitize_text_field(), but preserves
  # new lines (\n) and other whitespace, which are legitimate
  # input in textarea elements.
  #
  # @see sanitize_text_field()
  #
  # @param [string] str String to sanitize.
  # @return string Sanitized string.
  def sanitize_textarea_field( str )
    filtered = _sanitize_text_fields( str, true )

    # Filters a sanitized textarea field string.
    apply_filters( 'sanitize_textarea_field', filtered, str )
  end

  # Internal helper function to sanitize a string from user input or from the db
  #
  # @param [string] str String to sanitize.
  # @param [bool] keep_newlines optional Whether to keep newlines. Default: false.
  # @return string Sanitized string.
  def _sanitize_text_fields(str, keep_newlines = false)
    return '' unless str.is_a? String
    filtered = wp_check_invalid_utf8(str)
    # TODO continue implement _sanitize_text_fields
    filtered
  end

  # i18n friendly version of basename()
  #
  # @param [String] path   A path.
  # @param [String] suffix If the filename ends in suffix this will also be cut off.
  # @return [String]
  def wp_basename(path, suffix = '')
    CGI::unescape( File.basename( CGI.escape(path).gsub(/%2F|%5C/, '/'), suffix ))
  end

end