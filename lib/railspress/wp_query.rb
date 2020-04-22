=begin
 * Query API: WP_Query class
 *
 * file wp-includes\class-wp-query.php
=end

# The WordPress Query class.
#
# @link https://codex.wordpress.org/Function_Reference/WP_Query Codex page.
#
class Railspress::WP_Query
  include Railspress::Functions
  include Railspress::FormattingHelper
  include Railspress::Plugin
  include Railspress::TaxonomyLib

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

  # List of posts.
  #
  # @var array
  attr_accessor :posts

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

  # The current post.
  #
  # @var WP_Post
  attr_accessor :post

  # Signifies whether the current query is for a single post.
  #
  # @var bool
  attr_accessor :is_single

  # # Signifies whether the current query is for a preview.
  # #
  # # @var bool
  # attr_accessor :is_preview = false;

  # Signifies whether the current query is for a page.
  #
  # @var bool
  attr_accessor :is_page

  # Signifies whether the current query is for an archive.
  #
  # @var bool
  attr_accessor :is_archive

  # Signifies whether the current query is for an author archive.
  #
  # @var bool
  attr_accessor :is_author

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
    @is_single            = false
    # @is_preview           = false
    @is_page              = false
    @is_archive           = false
    @is_date              = false
    @is_year              = false
    @is_month             = false
    @is_day               = false
    @is_time              = false
    @is_author            = false
    @is_category          = false
    @is_tag               = false
    @is_tax               = false
    @is_search            = false
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
    @is_posts_page        = false
    @is_post_type_archive = false
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

  include Railspress::OptionsHelper
  include Railspress::PostsHelper

  # Parse a query string and set query type booleans.
  #
  # @param [string|array] query {
  #     Optional. Array or string of Query parameters.
  #
  # }
  def parse_query(p_query = '')
    if !p_query.blank?
      init
      @query = @query_vars = Railspress::Functions.wp_parse_args(p_query)
    elsif @query.blank?
      @query = @query_vars
    end
    @query_vars         = fill_query_vars(@query_vars)
    @qv = @query_vars
    # query_vars_changed = true

    # @is_robots = true unless @qv['robots']

    if !Railspress::PHP.is_scalar(@qv['p']) || @qv['p'].to_i < 0
      @qv['p'] = 0
      @qv['error'] = '404'
    else
      @qv['p'] = @qv['p'].to_i
    end

    @qv['page_id']  = Railspress::Functions.absint @qv['page_id']
    @qv['year']     = Railspress::Functions.absint @qv['year']
    @qv['monthnum'] = Railspress::Functions.absint @qv['monthnum']
    @qv['day']      = Railspress::Functions.absint @qv['day']
    @qv['w']        = Railspress::Functions.absint @qv['w']
    @qv['m']        = Railspress::PHP.is_scalar(@qv['m']) ? @qv['m'].gsub(/[^0-9]/, '') : ''
    @qv['paged']    = Railspress::Functions.absint @qv['paged']
    @qv['cat']      = @qv['cat'].gsub(/[^0-9,-]/, '')
    @qv['author']   = @qv['author'].gsub(/[^0-9,-]/, '')
    @qv['pagename'] = @qv['pagename'].strip
    @qv['name']     = @qv['name'].strip
    @qv['title']    = @qv['title'].strip
    @qv['hour']     = Railspress::Functions.absint(@qv['hour']) unless @qv['hour'] == ''
    @qv['minute']   = Railspress::Functions.absint(@qv['minute']) unless @qv['minute'] == ''
    @qv['second']   = Railspress::Functions.absint(@qv['second']) unless @qv['second'] == ''
    @qv['menu_order'] = Railspress::Functions.absint(@qv['menu_order']) unless @qv['menu_order'] == ''

    # Fairly insane upper bound for search string lengths.
    @qv['s'] = '' if !Railspress::PHP.is_scalar(@qv['s']) || !@qv['s'].blank? || @qv['s'].length > 1600

    # Compat. Map subpost to attachment.
    @qv['attachment'] = @qv['subpost'] unless @qv['subpost'] == ''
    @qv['attachment_id'] = @qv['subpost_id'] unless @qv['subpost_id'] == ''
    @qv['attachment_id'] = Railspress::Functions.absint @qv['attachment_id']

    if @qv['attachment'] != '' || @qv['attachment_id'] != 0
      @is_single = true
      @is_attachment = true
    elsif @qv['name'] != ''
      @is_single = true
    elsif @qv['p'] != 0
      @is_single = true
    elsif @qv['hour'] != '' && @qv['minute'] != '' && @qv['second'] != '' && @qv['year'] != '' && @qv['monthnum'] != '' && @qv['day'] != ''
      # If year, month, day, hour, minute, and second are set, a single
      # post is being queried.
      @is_single = true
    elsif @qv['pagename'] != '' || !@qv['page_id'].blank?
      @is_page = true
      @is_single = false
    else
      # Look for archive queries. Dates, categories, authors, search, post type archives.
      @is_search = true unless p_query['s'].blank?

      if @qv['second'] != ''
        @is_time = true
        @is_date = true
      end

      if @qv['minute'] != ''
        @is_time = true
        @is_date = true
      end

      if @qv['hour'] != ''
        @is_time = true
        @is_date = true
      end

      if @qv['day']
        # TODO continue with monthnum year m
      end

      @query_vars_hash = false
      parse_tax_query(@qv)

    end

    # TS_INFO added:
    if @qv['taxonomy'] == 'author'
      @is_author = true
      @query_vars['author'] = Railspress::User.where(user_nicename: @qv['slug']).pluck(:id).first
    end
    if @qv['taxonomy'] == 'category'
      @is_category = true
      @query_vars['cat'] = Railspress::Term.joins(:taxonomy).where(Railspress::Taxonomy.table_name => {taxonomy: @qv['taxonomy']}, slug: @qv['slug']).pluck(:term_id).first
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

    unless @qv['page_id'].blank?
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

  # Parses various taxonomy related query vars.
  #
  # @param [array] q The query variables.
  def parse_tax_query(q)
    if !q['tax_query'].blank? && q['tax_query'].is_a?(Array)
      tax_query = q['tax_query']
    else
      tax_query = []
    end

    if !q['taxonomy'].blank? && !q['term'].blank?
      tax_query << {
          taxonomy: q['taxonomy'],
          terms: [q['term'] ],
          field: 'slug'
      }
    end

    # TODO continue...

    # Fires after taxonomy-related query vars have been parsed.
    do_action( 'parse_tax_query', self )
  end

  # Sets up the WordPress query by parsing query string.
  #
  # @param [string|array] query URL query string or array of query arguments.
  # @return [WP_Post[]|int[]] Array of post objects or post IDs.
  def query(query)
    init
    @query = @query_vars = Railspress::Functions.wp_parse_args(query)
    # TODO ? self.get_posts
  end

  # Retrieve query variable.
  #
  # @param [string] query_var Query variable key.
  # @param [mixed]  default   Optional. Value to return if the query variable is not set. Default empty.
  # @return [mixed] Contents of the query variable.
	def get( query_var, default = '' )
    return @query_vars[ query_var ] unless @query_vars[ query_var ].nil?
    default
	end

  # Set query variable.
  #
  # @param [string] query_var Query variable key.
  # @param [mixed]  value     Query variable value.
  def set( query_var, value )
    @query_vars[ query_var ] = value
  end

  # Retrieve queried object.
  #
  # If queried object is not set, then the queried object will be set from
  # the category, tag, taxonomy, posts page, single post, page, or author
  # query variable. After it is set up, it will be returned.
  def get_queried_object
    return @queried_object unless @queried_object.blank?

    @queried_object = nil
    @queried_object_id = nil

    if @is_category || @is_tag || @is_tax
      if @is_category
        if get('cat')
          term = get_term( get('cat'), 'category' )
        elsif get('category_name')
          term = get_term_by('slug', get('category_name'), 'category' )
        end
      elsif @is_tag
        if get('tag_id')
          term = get_term( get('tag_id'), 'post_tag' )
        elsif get('tag')
          term = get_term_by('slug', get('tag'), 'post_tag' )
        end
      else
        #  For other tax queries, grab the first term from the first clause.
        # TODO continue..
      end

      if !term.blank? && !term.is_a?(Railspress::WP_Error)
        @queried_object = term
        @queried_object_id = term.term_id
      end
    elsif @is_post_type_archive
      post_type = get('post_type')
      if post_type.is_a?(Array)
        # ??? $post_type = reset( $post_type );
      end
      @queried_object = get_post_type_object(post_type)
    elsif @is_posts_page
      page_for_posts = get_option('page_for_posts')
      @queried_object = get_post(page_for_posts)
      @queried_object_id = @queried_object.id
    elsif @is_singular && !@post.blank?
      @queried_object = @post
      @queried_object_id = @post.id
    elsif is_author?
      @queried_object_id = get('author').to_i
      @queried_object    = Railspress::User.find(@queried_object_id) #  get_userdata(@queried_object_id)
    else
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

  # Is the query for an existing archive page?
  #
  # Month, Year, Category, Author, Post Type archive...
  #
  # @return bool
  def is_archive?
    @is_archive
  end

  # Is the query for an existing post type archive page?
  #
  # @param [mixed] post_types Optional. Post type or array of posts types to check against.
  # @return bool
  def is_post_type_archive?(post_types = '')
    return @is_post_type_archive if post_types.blank? || !@is_post_type_archive

    post_type = get('post_type')
    if post_type.is_a?(Array)
      post_type = post_type.first
    end
    post_type_object = get_post_type_object(post_type)

    post_types.include?(post_type_object.name)
  end

  # TODO  is_attachment

  # Is the query for an existing author archive page?
  #
  # If the $author parameter is specified, this function will additionally
  # check if the query is for one of the authors specified.
  #
  # @param [mixed] author Optional. User ID, nickname, nicename, or array of User IDs, nicknames, and nicenames
  # @return bool
  def is_author?( author = '' )
    return false unless @is_author

    return true if author.blank?

    author_obj = get_queried_object

    author = [author].map {|a| a.to_s}

    if author.include?(author_obj.id.to_s)
      return true
    elsif author.include?(author_obj.nickname)
      return true
    elsif author.include?(author_obj.user_nicename)
      return true
    end
    false
  end

  # Is the query for an existing category archive page?
  #
  # If the $category parameter is specified, this function will additionally
  # check if the query is for one of the categories specified.
  #
  # @param [mixed] category Optional. Category ID, name, slug, or array of Category IDs, names, and slugs.
  # @return bool
  def is_category?( category = '' )
    return false unless @is_category

    return true if category.blank?

    cat_obj = get_queried_object

    category = [category] unless category.is_a?(Array)
    category.map!(&:to_s)

    if category.include?(cat_obj.term_id.to_s)
      return true
    elsif category.include?(cat_obj.name)
      return true
    elsif category.include?(cat_obj.slug)
      return true
    end
    false
  end

  # Is the query for an existing tag archive page?
  #
  # If the tag parameter is specified, this function will additionally
  # check if the query is for one of the tags specified.
  #
  # @param [int|string|int[]|string[]] tag Optional. Tag ID, name, slug, or array of such
  #                                        to check against. Default empty.
  # @return [bool]
  def is_tag?( tag = '' )
    return false unless @is_tag

    return true if tag.blank?

    tag_obj = get_queried_object

    tag = [tag] unless tag.is_a?(Array)
    tag.map!(&:to_s)

    if tag.include?(tag_obj.term_id.to_s)
      return true
    elsif tag.include?(tag_obj.name)
      return true
    elsif tag.include?(tag_obj.slug)
      return true
    end
    false
  end

  # TODO is_tax

  # TODO is_comments_popup is_date ...

  # Is the query for the front page of the site?
  #
  # This is for what is displayed at your site's main URL.
  #
  # Depends on the site's "Front page displays" Reading Settings 'show_on_front' and 'page_on_front'.
  #
  # If you set a static page for the front page of your site, this function will return
  # true when viewing that page.
  #
  # Otherwise the same as @see WP_Query::is_home()
  #
  # @return bool True, if front of site.
  def is_front_page?
    # Most likely case.
    if 'posts' == get_option( 'show_on_front' ) && @is_home
      true
    elsif 'page' == get_option( 'show_on_front' ) && !get_option( 'page_on_front' ).blank? && is_page?( get_option( 'page_on_front' ) )
      true
    else
      false
    end
  end

  # Is the query for the blog homepage?
  #
  # This is the page which shows the time based blog content of your site.
  #
  # Depends on the site's "Front page displays" Reading Settings 'show_on_front' and 'page_for_posts'.
  #
  # If you set a static page for the front page of your site, this function will return
  # true only on the page you set as the "Posts page".
  #
  # @see WP_Query::is_front_page()
  #
  # @return [bool] True if blog view homepage.
  def is_home?
    @is_home
  end

  # Is the query for the Privacy Policy page?
  #
  # This is the page which shows the Privacy Policy content of your site.
  #
  # Depends on the site's "Change your Privacy Policy page" Privacy Settings 'wp_page_for_privacy_policy'.
  #
  # This function will return true only on the page you set as the "Privacy Policy page".
  #
  # @return [bool] True, if Privacy Policy page.
  def is_privacy_policy?
    if !get_option( 'wp_page_for_privacy_policy' ).blank? && is_page?( get_option( 'wp_page_for_privacy_policy' ) )
      true
    else
      false
    end
  end

  # Is the query for an existing single page?
  #
  # If the page parameter is specified, this function will additionally
  # check if the query is for one of the pages specified.
  #
  # @see WP_Query::is_single()
  # @see WP_Query::is_singular()
  #
  # @param [int|string|int[]|string[]] page Optional. Page ID, title, slug, path, or array of such
  #                                         to check against. Default empty.
  # @return [bool] Whether the query is for an existing single page.
  def is_page?(page = '')
    return false unless @is_page

    return true if page.blank?

    page_obj = get_queried_object()

    page = [page] unless page.is_a?(Array)
    page.map!(&:to_s)

    if page_obj.is_a?(Railspress::Page) && page.include?(page_obj.id.to_s)
      return true
    elsif page_obj.is_a?(Railspress::Page) && page.include?(page_obj.post_title)
      return true
    elsif page_obj.is_a?(Railspress::Page) && page.include?(page_obj.post_name)
      return true
    else
      page.each do |pagepath|
        next unless pagepath.include?('/')
        pagepath_obj = get_page_by_path(pagepath)
        if !pagepath_obj.blank? && pagepath_obj.id == page_obj.id
          return true
        end
      end
    end
    false
  end


end