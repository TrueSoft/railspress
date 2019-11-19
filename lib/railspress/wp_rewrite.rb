=begin
 * Rewrite API: WP_Rewrite class
 *
 * file wp-includes\class-wp-rewrite.php
=end
module Railspress
  require '../../app/helpers/railspress/options_helper'
  require 'railspress/plugin'
  require 'railspress/functions'
  # Core class used to implement a rewrite component API.
  #
  # The WordPress Rewrite class writes the rewrite module rules to the .htaccess
  # file. It also handles parsing the request to get the correct setup for the
  # WordPress Query class.
  #
  # The Rewrite along with WP class function as a front controller for WordPress.
  # You can add rules to trigger your page view and processing using this
  # component. The full functionality of a front controller does not exist,
  # meaning you can't define how the template files load based on the rewrite
  # rules.
  class WpRewrite

    include Railspress::OptionsHelper
    include Railspress::Plugin
    include Railspress::Functions

    # Permalink structure for posts.
    #
    # @var string
    attr_accessor :permalink_structure

    # Whether to add trailing slashes.
    #
    # @var bool
    attr_accessor :use_trailing_slashes

    # Base for the author permalink structure (example.com/$author_base/authorname).
    #
    # @var string
    attr_accessor :author_base

    # Permalink structure for author archives.
    #
    # @var string
    attr_accessor :author_structure

    # Permalink structure for date archives.
    #
    # @var string
    attr_accessor :date_structure

    # Permalink structure for pages.
    #
    # @var string
    attr_accessor :page_structure

    # Base of the search permalink structure (example.com/$search_base/query).
    #
    # @var string
    attr_accessor :search_base

    # Permalink structure for searches.
    #
    # @var string
    attr_accessor :search_structure

    # Comments permalink base.
    #
    # @var string
    attr_accessor :comments_base

    # Pagination permalink base.
    #
    # @var string
    attr_accessor :pagination_base

    # Comments pagination permalink base.
    #
    # @var string
    attr_accessor :comments_pagination_base

    # Feed permalink base.
    #
    # @var string
    attr_accessor :feed_base

    # Comments feed permalink structure.
    #
    # @var string
    attr_accessor :comment_feed_structure

    # Feed request permalink structure.
    #
    # @var string
    attr_accessor :feed_structure

    # The static portion of the post permalink structure.
    #
    # If the permalink structure is "/archive/%post_id%" then the front
    # is "/archive/". If the permalink structure is "/%year%/%postname%/"
    # then the front is "/".
    #
    # @var string
    #
    # @see WP_Rewrite::init()
    attr_accessor :front

    # The prefix for all permalink structures.
    #
    # If PATHINFO/index permalinks are in use then the root is the value of
    # `WP_Rewrite::$index` with a trailing slash appended. Otherwise the root
    # will be empty.
    #
    # @var string
    #
    # @see WP_Rewrite::init()
    # @see WP_Rewrite::using_index_permalinks()
    attr_accessor :root

    # The name of the index file which is the entry point to all requests.
    #
    # @var string
    attr_accessor :index

    # Variable name to use for regex matches in the rewritten query.
    #
    # @var string
    attr_accessor :matches

    # Rewrite rules to match against the request to find the redirect or query.
    #
    # @var array
    attr_accessor :rules

    # Additional rules added external to the rewrite class.
    #
    # Those not generated by the class, see add_rewrite_rule().
    #
    # @var array
    attr_accessor :extra_rules

    # Additional rules that belong at the beginning to match first.
    #
    # Those not generated by the class, see add_rewrite_rule().
    #
    # @var array
    attr_accessor :extra_rules_top

    # Rules that don't redirect to WordPress' index.php.
    #
    # These rules are written to the mod_rewrite portion of the .htaccess,
    # and are added by add_external_rule().
    #
    # @var array
    attr_accessor :non_wp_rules

    # Extra permalink structures, e.g. categories, added by add_permastruct().
    #
    # @var array
    attr_accessor :extra_permastructs

    # Endpoints (like /trackback/) added by add_rewrite_endpoint().
    #
    # @var array
    attr_accessor :endpoints

    # Whether to write every mod_rewrite rule for WordPress into the .htaccess file.
    #
    # This is off by default, turning it on might print a lot of rewrite rules
    # to the .htaccess file.
    #
    # @var bool
    #
    # @see WP_Rewrite::mod_rewrite_rules()
    attr_accessor :use_verbose_rules

    # Could post permalinks be confused with those of pages?
    #
    # If the first rewrite tag in the post permalink structure is one that could
    # also match a page name (e.g. %postname% or %author%) then this flag is
    # set to true. Prior to WordPress 3.3 this flag indicated that every page
    # would have a set of rules added to the top of the rewrite rules array.
    # Now it tells WP::parse_request() to check if a URL matching the page
    # permastruct is actually a page before accepting it.
    #
    # @var bool
    #
    # @see WP_Rewrite::init()
    attr_accessor :use_verbose_page_rules

    # Rewrite tags that can be used in permalink structures.
    #
    # These are translated into the regular expressions stored in
    # `WP_Rewrite::$rewritereplace` and are rewritten to the query
    # variables listed in WP_Rewrite::$queryreplace.
    #
    # Additional tags can be added with add_rewrite_tag().
    #
    # @var array
    attr_accessor :rewritecode

    # Regular expressions to be substituted into rewrite rules in place
    # of rewrite tags, see WP_Rewrite::$rewritecode.
    #
    # @var array
    attr_accessor :rewritereplace

    # Query variables that rewrite tags map to, see WP_Rewrite::$rewritecode.
    #
    # @var array
    attr_accessor :queryreplace

    # Supported default feeds.
    #
    # @var array
    attr_accessor :feeds

    def initialize
      @author_base = 'author'
      @search_base = 'search'
      @comments_base = 'comments'
      @pagination_base = 'page'
      @comments_pagination_base = 'comment-page'
      @feed_base = 'feed'
      @root = ''
      @index = 'index.php'
      @matches = ''
      @extra_rules = []
      @extra_rules_top = []
      @non_wp_rules = []
      @extra_permastructs = {}
      @use_verbose_rules = false
      @use_verbose_page_rules = true
      @rewritecode = [
          '%year%',
          '%monthnum%',
          '%day%',
          '%hour%',
          '%minute%',
          '%second%',
          '%postname%',
          '%post_id%',
          '%author%',
          '%pagename%',
          '%search%',
      ]
      @rewritereplace = [
          '([0-9]{4})',
          '([0-9]{1,2})',
          '([0-9]{1,2})',
          '([0-9]{1,2})',
          '([0-9]{1,2})',
          '([0-9]{1,2})',
          '([^/]+)',
          '([0-9]+)',
          '([^/]+)',
          '([^/]+?)',
          '(.+)'
      ]
      @queryreplace = [
          'year=',
          'monthnum=',
          'day=',
          'hour=',
          'minute=',
          'second=',
          'name=',
          'p=',
          'author_name=',
          'pagename=',
          's=',
      ]
      @feeds = ['feed', 'rdf', 'rss', 'rss2', 'atom']
    end

    # Determines whether permalinks are being used.
    #
    # This can be either rewrite module or permalink in the HTTP query string.
    #
    # @return [bool] True, if permalinks are enabled.
    def using_permalinks
      !@permalink_structure.blank?
    end

    # Determines whether permalinks are being used and rewrite module is not enabled.
    #
    # Means that permalink links are enabled and index.php is in the URL.
    #
    # @return bool Whether permalink links are enabled and index.php is in the URL.
    def using_index_permalinks
      return false if @permalink_structure.blank?

      # If the index is not in the permalink, we're using mod_rewrite.
      @permalink_structure.match '#^/*' + @index + '#'
    end

    # Determines whether permalinks are being used and rewrite module is enabled.
    #
    # Using permalinks and index.php is not in the URL.
    #
    # @return bool Whether permalink links are enabled and index.php is NOT in the URL.
    def using_mod_rewrite_permalinks
      using_permalinks && !using_index_permalinks
    end

    # Indexes for matches for usage in preg_*() functions.
    #
    # The format of the string is, with empty matches property value, '$NUM'.
    # The 'NUM' will be replaced with the value in the $number parameter. With
    # the matches property not empty, the value of the returned string will
    # contain that value of the matches property. The format then will be
    # '$MATCHES[NUM]', with MATCHES as the value in the property and NUM the
    # value of the $number parameter.
    #
    # @param [int] number Index number.
    # @return string
    def preg_index( number )
      match_prefix = '$'
      match_suffix = ''

      unless @matches.blank?
        match_prefix = '$' + @matches + '['
        match_suffix = ']'
      end

      "#{match_prefix}#{number}#{match_suffix}"
    end
    # Retrieves all page and attachments for pages URIs.
    #
    # The attachments are for those that have pages as parents and will be
    # retrieved.
    #
    # @return array Array of page URIs as first element and attachment URIs as second element.
    def page_uri_index
      # TODO implement class-wp-rewrite.php page_uri_index
    end

    # Retrieves all of the rewrite rules for pages.
    #
    # @return array Page rewrite rules.
    def page_rewrite_rules
      # The extra .? at the beginning prevents clashes with other regular expressions in the rules array.
      add_rewrite_tag( '%pagename%', '(.?.+?)', 'pagename=' )

      generate_rewrite_rules( get_page_permastruct(), EP_PAGES, true, true, false, false )
    end

    # TODO implement class-wp-rewrite.php get_date_permastruct
    # ...

    # Retrieves the permalink structure for categories.
    #
    # If the category_base property has no value, then the category structure
    # will have the front property value, followed by 'category', and finally
    # '%category%'. If it does, then the root property will be used, along with
    # the category_base property value.
    #
    # @return [string|false] False on failure. Category permalink structure.
    def get_category_permastruct
      get_extra_permastruct( 'category' )
    end

    # Retrieve the permalink structure for tags.
    #
    # If the tag_base property has no value, then the tag structure will have
    # the front property value, followed by 'tag', and finally '%tag%'. If it
    # does, then the root property will be used, along with the tag_base
    # property value.
    #
    # @return [string|false] False on failure. Tag permalink structure.
    def get_tag_permastruct
      get_extra_permastruct( 'post_tag' )
    end

    # Retrieves an extra permalink structure by name.
    #
    # @param [string] name Permalink structure name.
    # @return string|false False if not found. Permalink structure string.
    def get_extra_permastruct( name )
      return false if @permalink_structure.blank?
      return @extra_permastructs[ name ]['struct'] unless @extra_permastructs[ name ].nil?
      false
    end

    # TODO implement class-wp-rewrite.php get_author_permastruct, get_search_permastruct

    # Retrieves the page permalink structure.
    #
    # The permalink structure is root property, and '%pagename%'. Will set the
    # page_structure property and then return it without attempting to set the
    # value again.
    #
    #
    # @return string|false False if not found. Permalink structure string.
    def get_page_permastruct
      return @page_structure unless @page_structure.nil?

      if @permalink_structure.blank?
        @page_structure = ''
        return false
      end

      @page_structure = @root + '%pagename%'
    end

    # TODO implement class-wp-rewrite.php get_feed_permastruct, get_comment_feed_permastruct

    # Sets up the object's properties.
    #
    # The 'use_verbose_page_rules' object property will be set to true if the
    # permalink structure begins with one of the following: '%postname%', '%category%',
    # '%tag%', or '%author%'.
    #
    def init
      @extra_rules         = []
      @non_wp_rules = []
      @endpoints = []
      begin
        @permalink_structure = get_option( 'permalink_structure' )
      # rescue Mysql2::Error::ConnectionError
      #   warn("[WARN] couldn't connect to database. Skipping Railspress.GLOBAL::wp_rewrite::permalink_structure initialization")
      #   @permalink_structure = '/%postname%'
      end
      if @permalink_structure == false && Rails.env.test?
        @permalink_structure = '/%postname%'
      end
      @front               = @permalink_structure[0, @permalink_structure.index('%')]
      @root                = ''

      @root = @index + '/' if using_index_permalinks

      @author_structure = nil
      @date_structure = nil
      @page_structure = nil
      @search_structure = nil
      @feed_structure = nil
      @comment_feed_structure = nil
      @use_trailing_slashes = ( '/' == @permalink_structure[-1, 1])

      # Enable generic rules for pages if permalink structure doesn't begin with a wildcard.
      if @permalink_structure.match /^[^%]*%(?:postname|category|tag|author)%/
        @use_verbose_page_rules = true
      else
        @use_verbose_page_rules = false
      end
    end


  end
end