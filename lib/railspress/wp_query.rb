=begin
 * Query API: WP_Query class
 *
 * file wp-includes\class-wp-query.php
=end

module Railspress

  # The WordPress Query class.
  #
  # @link https://codex.wordpress.org/Function_Reference/WP_Query Codex page.
  #
  class WP_Query
    include Railspress::Functions
    include Railspress::FormattingHelper
    include Railspress::Plugin

    # Holds the data for a single object that is queried.
    #
    # Holds the contents of a post, page, category, attachment.
    #
    # @var object|array
    attr_accessor :queried_object

    # The ID of the queried object.
    #
    # @var int
    attr_accessor :queried_object_id

    # # List of posts.
    # #
    # # @var array
    # attr_accessible :posts;
    #
    # # The amount of posts for the current query.
    # #
    # # @var int
    # attr_accessible :post_count = 0;
    #
    # # Index of the current item in the loop.
    # #
    # # @var int
    # attr_accessible :current_post = -1;
    #
    # # Whether the loop has started and the caller is in the loop.
    # #
    # # @var bool
    # attr_accessible :in_the_loop = false;
    #
    # # The current post.
    # #
    # # @var WP_Post
    # attr_accessible :post;
    #
    #
    # # Signifies whether the current query is for a single post.
    # #
    # # @var bool
    # attr_accessible :is_single = false;
    #
    # # Signifies whether the current query is for a preview.
    # #
    # # @var bool
    # attr_accessible :is_preview = false;
    #
    # # Signifies whether the current query is for a page.
    # #
    # # @var bool
    # attr_accessible :is_page = false;

    # Signifies whether the current query is for a category archive.
    #
    # @var bool
    attr_accessor :is_category

    # Signifies whether the current query is for a tag archive.
    #
    # @var bool
    attr_accessor :is_tag

    # Signifies whether the current query is for a taxonomy archive.
    #
    # @var bool
    attr_accessor :is_tax


    # Signifies whether the current query is for the site homepage.
    #
    # @var bool
    attr_accessor :is_home

    # Signifies whether the current query is for the Privacy Policy page.
    #
    # @var bool
    attr_accessor :is_privacy_policy


    # Signifies whether the current query is for an attachment page.
    #
    # @var bool
    attr_accessor :is_attachment

    # Signifies whether the current query is for an existing single post of any post type
    # (post, attachment, page, custom post types).
    #
    # @var bool
    attr_accessor :is_singular


    def init_query_flags
      # @is_single            = false
      # @is_preview           = false
      # @is_page              = false
      # @is_archive           = false
      # @is_date              = false
      # @is_year              = false
      # @is_month             = false
      # @is_day               = false
      # @is_time              = false
      # @is_author            = false
      @is_category          = false
      @is_tag               = false
      @is_tax               = false
      # @is_search            = false
      # @is_feed              = false
      # @is_comment_feed      = false
      # @is_trackback         = false
      @is_home              = false
      @is_privacy_policy    = false
      # @is_404               = false
      # @is_paged             = false
      # @is_admin             = false
      @is_attachment        = false
      @is_singular          = false
      # @is_robots            = false
      # @is_posts_page        = false
      # @is_post_type_archive = false
    end

    def init
      # unset( $this->posts );
      # unset( $this->query );
      # $this->query_vars = array();
      @queried_object = nil
      @queried_object_id = nil
      # $this->post_count   = 0;
      # $this->current_post = -1;
      # $this->in_the_loop  = false;
      # unset( $this->request );
      # unset( $this->post );
      # unset( $this->comments );
      # unset( $this->comment );
      # $this->comment_count         = 0;
      # $this->current_comment       = -1;
      # $this->found_posts           = 0;
      # $this->max_num_pages         = 0;
      # $this->max_num_comment_pages = 0;

      init_query_flags
    end

    # Reparse the query vars.
    def parse_query_vars
      parse_query
    end

    # Fills in the query variables, which do not exist within the parameter.
    #
    # @param [array] array Defined query variables.
    # @return [array] Complete query variables with undefined ones filled in empty.
    def fill_query_vars(array)
      keys = [
          'error',
          'm',
          'p',
          'post_parent',
          'subpost',
          'subpost_id',
          'attachment',
          'attachment_id',
          'name',
          'static',
          'pagename',
          'page_id',
          'second',
          'minute',
          'hour',
          'day',
          'monthnum',
          'year',
          'w',
          'category_name',
          'tag',
          'cat',
          'tag_id',
          'author',
          'author_name',
          'feed',
          'tb',
          'paged',
          'meta_key',
          'meta_value',
          'preview',
          's',
          'sentence',
          'title',
          'fields',
          'menu_order',
          'embed',
      ]
      keys.each do |key|
        array[key] ||= ''
      end

      array_keys = [
          'category__in',
          'category__not_in',
          'category__and',
          'post__in',
          'post__not_in',
          'post_name__in',
          'tag__in',
          'tag__not_in',
          'tag__and',
          'tag_slug__in',
          'tag_slug__and',
          'post_parent__in',
          'post_parent__not_in',
          'author__in',
          'author__not_in',
      ]
      array_keys.each do |key|
        array[key] ||= []
      end
      array
    end

    # Parse a query string and set query type booleans.
    #
    # @param [string|array] query {
    #     Optional. Array or string of Query parameters.
    #
    # }
    def parse_query(p_query = '')
      if !p_query.blank?
        init
        @query = @query_vars = wp_parse_args(p_query)
      elsif @query.blank?
        @query = @query_vars
      end
      @query_vars         = fill_query_vars(@query_vars)
      @qv = @query_vars

      # TODO continue

      if @qv['attachment'] != '' || !@qv['attachment_id'].blank?
        @is_single = true
        @is_attachment = true
      elsif @qv['name'] != ''
        @is_single = true
      else

      end

      # @is_feed = true unless @qv['feed'].blank?
      # @is_embed = true unless @qv['embed'].blank?
      # @is_trackback = true unless @qv['tb'].blank?
      # @is_paged = true unless @qv['paged'].blank?

      # if we're previewing inside the write screen

      if @qv['pagename'] != ''
        queried_object = @page


        if 'page' == get_option( 'show_on_front' ) && !@queried_object_id.nil? && @queried_object_id.to_s == get_option( 'page_for_posts' ).to_s
          @is_page       = false
          @is_home       = true
          @is_posts_page = true
        end

        if !@queried_object_id.nil? && @queried_object_id.to_s == get_option( 'wp_page_for_privacy_policy' ).to_s
          @is_privacy_policy = true
        end
      end

      if @qv['page_id']
        if 'page' == get_option( 'show_on_front' ) && @qv['page_id'] == get_option( 'page_for_posts' )
          @is_page       = false
          @is_home       = true
          @is_posts_page = true
        end

        if @qv['page_id'] == get_option( 'wp_page_for_privacy_policy' )
          @is_privacy_policy = true
        end
      end

      unless @qv['post_type'].blank?

      end

      @is_singular = @is_single || @is_page || @is_attachment
      # Done correcting is_* for page_on_front and page_for_posts

      # Fires after the main query vars have been parsed.
      # TODO do_action_ref_array( 'parse_query', array( &$this ) )
    end

    # Sets up the WordPress query by parsing query string.
    #
    # @param [string|array] query URL query string or array of query arguments.
    # @return [WP_Post[]|int[]] Array of post objects or post IDs.
    def query(query)
      init
      @query = @query_vars = Functions.wp_parse_args(query)
      # TODO ? self.get_posts
    end

    # Retrieve queried object.
    #
    # If queried object is not set, then the queried object will be set from
    # the category, tag, taxonomy, posts page, single post, page, or author
    # query variable. After it is set up, it will be returned.
    def get_queried_object
      return @queried_object unless @queried_object.nil?

      @queried_object = nil
      @queried_object_id = nil

      if @is_category || @is_tag || @is_tax
      elsif @is_post_type_archive
      elsif @is_posts_page
        page_for_posts = get_option('page_for_posts')
        @queried_object = get_post(page_for_posts)
        @queried_object_id = @queried_object.id
      elsif @is_singular && !@post.blank?
      elsif @is_author
      end
      @queried_object
    end

    # Retrieve ID of the current queried object.
    #
    # @return int
    def get_queried_object_id
      get_queried_object

      return @queried_object_id unless @queried_object_id.blank?

      return 0
    end

    def initialize(p_query = '')
      query(p_query) unless p_query.nil?
    end
  end
end