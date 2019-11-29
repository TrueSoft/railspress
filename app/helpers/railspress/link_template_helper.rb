=begin
 * WordPress Link Template Functions
 *
 * file wp-includes\link-template.php
=end
module Railspress::LinkTemplateHelper

  # Displays the permalink for the current post.
  #
  # @param [int|WP_Post] post Optional. Post ID or post object. Default is the global `$post`.
  def the_permalink(post = 0)
    # Filters the display of the permalink for the current post.
    esc_url(apply_filters('the_permalink', get_permalink(post), post))
  end

  # Retrieves a trailing-slashed string if the site is set for adding trailing slashes.
  #
  # Conditionally adds a trailing slash if the permalink structure has a trailing
  # slash, strips the trailing slash if not. The string is passed through the
  # {@see 'user_trailingslashit'} filter. Will remove trailing slash from string, if
  # site is not set to have them.
  #
  # @param [string] string      URL with or without a trailing slash.
  # @param [string] type_of_url Optional. The type of URL being considered (Accepts 'single', 'single_trackback',
  #                            'single_feed', 'single_paged', 'commentpaged', 'paged', 'home', 'feed',
  #                            'category', 'page', 'year', 'month', 'day', 'post_type_archive')
  #                            for use in the filter. Default empty string.
  # @return string The URL with the trailing slash appended or stripped.
  def user_trailingslashit(string, type_of_url = '')
    if Railspress.GLOBAL.wp_rewrite.use_trailing_slashes
      string = trailingslashit(string)
    else
      string = untrailingslashit(string)
    end

    # Filters the trailing-slashed string, depending on whether the site is set to use trailing slashes.
    apply_filters('user_trailingslashit', string, type_of_url)
  end

  def get_permalink(post, leavename = false)
    rewritecode = [
        '%year%',
        '%monthnum%',
        '%day%',
        '%hour%',
        '%minute%',
        '%second%',
        leavename ? '' : '%postname%',
        '%post_id%',
        '%category%',
        '%author%',
        leavename ? '' : '%pagename%',
        ]

    if  post.is_a?(Railspress::WpPost) && false # ?? 'sample' == post.filter
      sample = true
    else
      post   = get_post( post )
      sample = false
    end

    return false if post.id.blank?

    if post.post_type == 'page'
      return get_page_link(post, leavename, sample)
    elsif post.post_type == 'attachment'
      return get_attachment_link(post, leavename)
    elsif get_post_types({'_builtin' => false}).include?(post.post_type)
      return get_post_permalink(post, leavename, sample)
    end
    permalink = get_option( 'permalink_structure' )
    # Filters the permalink structure for a post before token replacement occurs.
    #
    # Only applies to posts with post_type of 'post'.
    permalink = apply_filters('pre_post_link', permalink, post, leavename)

    if !permalink.blank? && !['draft', 'pending', 'auto-draft', 'future'].include?(post.post_status)
      category = ''
      if permalink.include? '%category%'
        cats = get_the_category(post.id)
        if cats
          # TODO cats = wp_list_sort(cats, {term_id: 'ASC'})
          # Filters the category that gets used in the %category% permalink token.
          #
          # @param WP_Term  $cat  The category to use in the permalink.
          # @param array    $cats Array of all categories (WP_Term objects) associated with the post.
          # @param WP_Post  $post The post in question.
          category_object = apply_filters( 'post_link_category', cats[0], cats, post )

          category_object = get_term( category_object, 'category' )
          category        = category_object.slug
          if category_object.parent
            category = get_category_parents( category_object.parent, false, '/', true ) + category
          end
          # show default category in permalinks, without
          # having to assign it explicitly
          if category.blank?
            default_category = get_term( get_option( 'default_category' ), 'category' )
            if  default_category && !default_category.is_a?(Railspress::WP_Error)
              category = default_category.slug
            end
          end
        end
      end
      author = ''
      if permalink.include? '%author%'
        author = post.author.user_nicename
      end
      unixtime = post.post_date
      date     = unixtime.strftime('%Y %m %d %H %M %S').split(' ')
      		rewritereplace = [
      			date[0],
      			date[1],
      			date[2],
      			date[3],
      			date[4],
      			date[5],
      			post.post_name,
      			post.ID.to_s,
      			category,
      			author,
      			post.post_name,
      		]
      (1 .. rewritecode.length - 1).each do |i|
        permalink = permalink.gsub rewritecode[i], rewritereplace[i] unless rewritecode[i].blank?
      end
      permalink      = home_url(permalink)
      permalink      = user_trailingslashit(permalink, 'single')
    else # if they're not using the fancy permalink option
  		permalink = home_url('?p=' + post.id)
    end

    # Filters the permalink for a post.
    #
    # Only applies to posts with post_type of 'post'.
	  apply_filters('post_link', permalink, post, leavename)
  end

  # Retrieves the permalink for a post of a custom post type.
  #
  # @global WP_Rewrite $wp_rewrite
  #
  # @param [int|WP_Post] id        Optional. Post ID or post object. Default is the global `$post`.
  # @param [bool]        leavename Optional, defaults to false. Whether to keep post name. Default false.
  # @param [bool]        sample    Optional, defaults to false. Is it a sample permalink. Default false.
  # @return string|WP_Error The post permalink.
  def get_post_permalink(id = 0, leavename = false, sample = false )
    # global $wp_rewrite;

    post = get_post(id)

    return post if post.is_a? Railspress::WP_Error # is_wp_error( post )

    post_link = Railspress.GLOBAL.wp_rewrite.get_extra_permastruct( post.post_type )

    slug = post.post_name

    draft_or_pending = get_post_status(post) && ['draft', 'pending', 'auto-draft', 'future'].include?( get_post_status(post))

    post_type = get_post_type_object(post.post_type)

    if post_type.hierarchical
        slug = get_page_uri(post)
    end

    if !post_link.blank? && (!draft_or_pending || sample)
      unless leavename
        post_link = post_link.gsub('%' + post.post_type + '%', slug)
      end
      post_link = home_url(user_trailingslashit(post_link))
    else
      if post_type.query_var && (!post.post_status.nil? && !draft_or_pending)
        post_link = {post_type.query_var.to_sym => slug}.to_query
      else
        post_link = {post_type: post.post_type, p: post.id}.to_query
      end
      post_link = home_url('?' + post_link)
    end

    # Filters the permalink for a post of a custom post type.
    apply_filters( 'post_type_link', post_link, post, leavename, sample )
  end

  ##  Retrieves the permalink for the current page or page ID.
  def get_page_link(post, leavename = false, sample = false)
    # post = get_post(post)

    if 'page' == get_option('show_on_front') && post.id == get_option('page_on_front')
      link = main_app.root_path
    else
      link = _get_page_link(post, leavename, sample)
    end

    # Filters the permalink for a page.
    apply_filters('page_link', link, post.id, sample)
  end

  # Retrieves the page permalink.
  #
  # Ignores page_on_front. Internal use only.
  def _get_page_link(post = false, leavename = false, sample = false)
    # global $wp_rewrite
    # post = get_post( post )
    draft_or_pending = ['draft', 'pending', 'auto-draft'].include?(post.post_status)
    link = Railspress.GLOBAL.wp_rewrite.get_page_permastruct

    if !link.blank? && ((!post.post_status.blank? && !draft_or_pending) || sample)
      unless leavename
        link = link.gsub('%pagename%', get_page_uri(post))
      end
      link = home_url(link)
      link = user_trailingslashit(link, 'page')
    else
      link = home_url(page_id: post.id)
    end

    # Filters the permalink for a non-page_on_front page.
    apply_filters('_get_page_link', link, post.id)
  end

  # Retrieves the permalink for a post type archive.
  #
  # @param [string] post_type Post type.
  # @return string|false The post type archive permalink.
  def get_post_type_archive_link( post_type )
    #global $wp_rewrite;
    post_type_obj = get_post_type_object( post_type )
    return false if !post_type_obj

    if ( 'post' == post_type )
      show_on_front  = get_option( 'show_on_front' )
      page_for_posts = get_option( 'page_for_posts' )

      if 'page' == show_on_front && page_for_posts
        link = get_permalink( page_for_posts )
      else
        link = get_home_url
      end
      # This filter is documented in wp-includes/link-template.php
      return apply_filters( 'post_type_archive_link', link, post_type )
    end

    return false unless post_type_obj.has_archive

    if get_option( 'permalink_structure' ) && PHP.is_array( post_type_obj.rewrite )
      struct = ( true == post_type_obj.has_archive ) ? post_type_obj.rewrite['slug'] : post_type_obj.has_archive
      if post_type_obj.rewrite['with_front']
        struct = wp_rewrite.front + struct;
      else
        struct = wp_rewrite.root + struct;
      end
      link = home_url( user_trailingslashit( struct, 'post_type_archive' ) )
    else
      link = home_url( '?post_type=' + post_type )
    end

    # Filters the post type archive permalink.
    apply_filters( 'post_type_archive_link', link, post_type )
  end

  # Retrieves the adjacent post.
  #
  # Can either be next or previous post.
  #
  # @global wpdb $wpdb WordPress database abstraction object.
  #
  # @param [bool]         in_same_term   Optional. Whether post should be in a same taxonomy term. Default false.
  # @param [array|string] excluded_terms Optional. Array or comma-separated list of excluded term IDs. Default empty.
  # @param [bool]         previous       Optional. Whether to retrieve previous post. Default true
  # @param [string]       taxonomy       Optional. Taxonomy, if $in_same_term is true. Default 'category'.
  # @return null|string|WP_Post Post object if successful. Null if global $post is not set. Empty string if no
  #                             corresponding post exists.
  def get_adjacent_post( in_same_term = false, excluded_terms = '', previous = true, taxonomy = 'category' )
    # TODO default_filter based on @post language
    if previous
      if Railspress.multi_language
        Railspress::Post.published.joins(:languages).where(default_filter).where('post_date < ?', @post.post_date).order(post_date: :desc).first
      else
        Railspress::Post.published.where('post_date < ?', @post.post_date).order(post_date: :desc).first
      end
    else
      if Railspress.multi_language
        Railspress::Post.published.joins(:languages).where(default_filter).where('post_date > ?', @post.post_date).order(post_date: :asc).first
      else
        Railspress::Post.published.where('post_date > ?', @post.post_date).order(post_date: :asc).first
      end
    end
  end
  # TODO get_adjacent_post_rel_link adjacent_posts_rel_link adjacent_posts_rel_link_wp_head next_post_rel_link prev_post_rel_link get_boundary_post

  # Retrieves the previous post link that is adjacent to the current post.
  #
  # @param [string]       format         Optional. Link anchor format. Default '&laquo; %link'.
  # @param [string]       link           Optional. Link permalink format. Default '%title'.
  # @param [bool]         in_same_term   Optional. Whether link should be in a same taxonomy term. Default false.
  # @param [array|string] excluded_terms Optional. Array or comma-separated list of excluded term IDs. Default empty.
  # @param [string]       taxonomy       Optional. Taxonomy, if $in_same_term is true. Default 'category'.
  # @return string The link URL of the previous post in relation to the current post.
  def get_previous_post_link( format = '&laquo; %link', link = '%title', in_same_term = false, excluded_terms = '', taxonomy = 'category' )
    get_adjacent_post_link( format, link, in_same_term, excluded_terms, true, taxonomy )
  end

  # Displays the previous post link that is adjacent to the current post.
  #
  # @see get_previous_post_link()
  #
  # @param [string]       format         Optional. Link anchor format. Default '&laquo; %link'.
  # @param [string]       link           Optional. Link permalink format. Default '%title'.
  # @param [bool]         in_same_term   Optional. Whether link should be in a same taxonomy term. Default false.
  # @param [array|string] excluded_terms Optional. Array or comma-separated list of excluded term IDs. Default empty.
  # @param [string]       taxonomy       Optional. Taxonomy, if $in_same_term is true. Default 'category'.
  def previous_post_link( format = '&laquo; %link', link = '%title', in_same_term = false, excluded_terms = '', taxonomy = 'category' )
    get_previous_post_link(format, link, in_same_term, excluded_terms, taxonomy )
  end

  # Retrieves the next post link that is adjacent to the current post.
  #
  # @param [string]       format         Optional. Link anchor format. Default '&laquo; %link'.
  # @param [string]       link           Optional. Link permalink format. Default '%title'.
  # @param [bool]         in_same_term   Optional. Whether link should be in a same taxonomy term. Default false.
  # @param [array|string] excluded_terms Optional. Array or comma-separated list of excluded term IDs. Default empty.
  # @param [string]       taxonomy       Optional. Taxonomy, if $in_same_term is true. Default 'category'.
  # @return string The link URL of the next post in relation to the current post.
  def get_next_post_link( format = '%link &raquo;', link = '%title', in_same_term = false, excluded_terms = '', taxonomy = 'category' )
    get_adjacent_post_link( format, link, in_same_term, excluded_terms, false, taxonomy )
  end

  # Displays the next post link that is adjacent to the current post.
  #
  # @see get_next_post_link()
  #
  # @param [string]       format         Optional. Link anchor format. Default '&laquo; %link'.
  # @param [string]       link           Optional. Link permalink format. Default '%title'
  # @param [bool]         in_same_term   Optional. Whether link should be in a same taxonomy term. Default false.
  # @param [array|string] excluded_terms Optional. Array or comma-separated list of excluded term IDs. Default empty.
  # @param [string]       taxonomy       Optional. Taxonomy, if $in_same_term is true. Default 'category'.
  def next_post_link( format = '%link &raquo;', link = '%title', in_same_term = false, excluded_terms = '', taxonomy = 'category' )
    get_next_post_link( format, link, in_same_term, excluded_terms, taxonomy )
  end


  # Navigation links

  # Retrieves the previous post that is adjacent to the current post.
  #
  # @param [bool]         in_same_term   Optional. Whether post should be in a same taxonomy term. Default false.
  # @param [array|string] excluded_terms Optional. Array or comma-separated list of excluded term IDs. Default empty.
  # @param [string]       taxonomy       Optional. Taxonomy, if $in_same_term is true. Default 'category'.
  # @return null|string|WP_Post Post object if successful. Null if global $post is not set. Empty string if no
  #                             corresponding post exists.
  def get_previous_post( in_same_term = false, excluded_terms = '', taxonomy = 'category' )
    get_adjacent_post( in_same_term, excluded_terms, true, taxonomy );
  end

  # Retrieves the next post that is adjacent to the current post.
  #
  # @param [bool]         in_same_term   Optional. Whether post should be in a same taxonomy term. Default false.
  # @param [array|string] excluded_terms Optional. Array or comma-separated list of excluded term IDs. Default empty.
  # @param [string]       taxonomy       Optional. Taxonomy, if $in_same_term is true. Default 'category'.
  # @return null|string|WP_Post Post object if successful. Null if global $post is not set. Empty string if no
  #                             corresponding post exists.
  def get_next_post( in_same_term = false, excluded_terms = '', taxonomy = 'category' )
    get_adjacent_post( in_same_term, excluded_terms, false, taxonomy );
  end

  # Retrieves the adjacent post link.
  #
  # Can be either next post link or previous.
  #
  # @param [string]       format         Link anchor format.
  # @param [string]       link           Link permalink format.
  # @param [bool]         in_same_term   Optional. Whether link should be in a same taxonomy term. Default false.
  # @param [array|string] excluded_terms Optional. Array or comma-separated list of excluded terms IDs. Default empty.
  # @param [bool]         previous       Optional. Whether to display link to previous or next post. Default true.
  # @param [string]       taxonomy       Optional. Taxonomy, if $in_same_term is true. Default 'category'.
  # @return string The link URL of the previous or next post in relation to the current post.
  def get_adjacent_post_link( format, link, in_same_term = false, excluded_terms = '', previous = true, taxonomy = 'category')
    if previous && false # TODO is_attachment()
      post = get_post( @post.post_parent )
    else
      post = get_adjacent_post( in_same_term, excluded_terms, previous, taxonomy )
    end
    if post.nil?
      output = ''
    else
      title = post.post_title
      title = previous ? t('railspress.post.show.prev_post') : t('railspress.post.show.next_post') if post.post_title.blank?

      # This filter is documented in wp-includes/post-template.php
      title = apply_filters( 'the_title', title, post.ID )

      date = post.post_date.strftime( get_option( 'date_format' ) ) # TODO use php format
      rel  = previous ? 'prev' : 'next'

      string = '<a href="' + (Railspress.links_to_wp ? get_permalink(post) : wp_url_to_relative_url(get_permalink(post))) + '" rel="' + rel + '">'
      inlink = link.gsub( '%title', title)
      inlink = inlink.gsub( '%date', date)
      inlink = string + inlink + '</a>'

      output = format.gsub( '%link', inlink)

    end
    adjacent = previous ? 'previous' : 'next'

   # Filters the adjacent post link.
   #
   # The dynamic portion of the hook name, `$adjacent`, refers to the type
   # of adjacency, 'next' or 'previous'.
   #
   # @param string  output   The adjacent post link.
   # @param string  format   Link anchor format.
   # @param string  link     Link permalink format.
   # @param WP_Post post     The adjacent post.
   # @param string  adjacent Whether the post is previous or next.
    apply_filters( "#{adjacent}_post_link", output, format, link, post, adjacent )
  end

  # TODO adjacent_post_link get_pagenum_link get_next_posts_page_link next_posts get_next_posts_link next_posts_link get_previous_posts_page_link previous_posts

  # Retrieves the previous posts page link.
  #
  # @global int $paged
  #
  # @param [string] label Optional. Previous page link text.
  # @return [string|void] HTML-formatted previous page link.
  def get_previous_posts_link( label = nil )
    # global $paged;

    label = t('railspress.post.index.prev_page') if label.nil?

    if ! is_single() && $paged > 1
      # Filters the anchor tag attributes for the previous posts page link.
      #
      # @param string $attributes Attributes for the anchor tag.
      attr = apply_filters( 'previous_posts_link_attributes', '' )
      return '<a href="' + previous_posts( false ) + "\" #{attr}>" + label.gsub( /&([^#])(?![a-z]{1,8};)/i, '&#038;$1') + '</a>'
    end
  end

  # Displays the previous posts page link.
  #
  # @param [string] label Optional. Previous page link text.
  def previous_posts_link( label = nil )
    get_previous_posts_link( label )
  end

  # Retrieves the post pages link navigation for previous and next pages.
  #
  # @global WP_Query $wp_query
  #
  # @param [string|array] args {
  #     Optional. Arguments to build the post pages link navigation.
  #
  #     @type string :sep      Separator character. Default '&#8212;'.
  #     @type string :prelabel Link text to display for the previous page link.
  #                            Default '&laquo; Previous Page'.
  #     @type string :nxtlabel Link text to display for the next page link.
  #                            Default 'Next Page &raquo;'.
  # }
  # @return [string] The posts link navigation.
  def get_posts_nav_link( args = {} )
    # global $wp_query;

    ret = ''

    if ( ! is_singular() )
        defaults = {
            sep:	 ' &#8212; ',
            prelabel:	 __( '&laquo; Previous Page' ),
            nxtlabel:	 __( 'Next Page &raquo;' ),
        }
    args     = wp_parse_args( args, defaults )

    max_num_pages = $wp_query.max_num_pages;
    paged         = get_query_var( 'paged' )

    # only have sep if there's both prev and next results
    args[:sep] = '' if paged < 2 || paged >= max_num_pages

    if max_num_pages > 1
      ret  = get_previous_posts_link( args[:prelabel] )
      ret += args[:sep].gsub(/&([^#])(?![a-z]{1,8};)/i, '&#038;$1' )
      ret += get_next_posts_link( args['nxtlabel'] )
    end
    end
    ret
    end

    # Displays the post pages link navigation for previous and next pages.
    #
    # @param [string] sep      Optional. Separator for posts navigation links. Default empty.
    # @param [string] prelabel Optional. Label for previous pages. Default empty.
    # @param [string] nxtlabel Optional Label for next pages. Default empty.
    #/
    def posts_nav_link( sep = '', prelabel = '', nxtlabel = '' )
      args =  { sep: sep, prelabel: prelabel, nxtlabel: nxtlabel } # TODO array_filter
      get_posts_nav_link( args )
    end

    # Retrieves the navigation to next/previous post, when applicable.
    #
    # @param [array] args {
    #     Optional. Default post navigation arguments. Default empty array.
    #
    #     @type string       :prev_text          Anchor text to display in the previous post link. Default '%title'.
    #     @type string       :next_text          Anchor text to display in the next post link. Default '%title'.
    #     @type bool         :in_same_term       Whether link should be in a same taxonomy term. Default false.
    #     @type array|string :excluded_terms     Array or comma-separated list of excluded term IDs. Default empty.
    #     @type string       :taxonomy           Taxonomy, if `$in_same_term` is true. Default 'category'.
    #     @type string       :screen_reader_text Screen reader text for nav element. Default 'Post navigation'.
    # }
    # @return string Markup for post links.
    def get_the_post_navigation( args = {} )
      args = Railspress::Functions.wp_parse_args(
          args,
          {
              prev_text: '%title',
              next_text: '%title',
              in_same_term: false,
              excluded_terms: '',
              taxonomy: 'category',
              screen_reader_text: t( 'railspress.post.show.navigation' ),
          }
      )

      navigation = ''

      previous = get_previous_post_link(
          '<div class="nav-previous">%link</div>',
          args[:prev_text],
          args[:in_same_term],
          args[:excluded_terms],
          args[:taxonomy]
      )

      next_ = get_next_post_link(
          '<div class="nav-next">%link</div>',
          args[:next_text],
          args[:in_same_term],
          args[:excluded_terms],
          args[:taxonomy]
      )

      # Only add markup if there's somewhere to navigate to.
      if  previous || next_
        navigation = _navigation_markup( previous + next_, 'post-navigation', args[:screen_reader_text] )
      end

      navigation
    end

  # Displays the navigation to next/previous post, when applicable.
  #
  # @param [array] args Optional. See get_the_post_navigation() for available arguments.
  #                     Default empty array.
  def the_post_navigation(args = {} )
    get_the_post_navigation( args )
  end

  # Returns the navigation to next/previous set of posts, when applicable.
  #
  # @global WP_Query $wp_query WordPress Query object.
  #
  # @param [array] args {
  #     Optional. Default posts navigation arguments. Default empty array.
  #
  #     :prev_text          Anchor text to display in the previous posts link.
  #                         Default 'Older posts'.
  #     :next_text          Anchor text to display in the next posts link.
  #                         Default 'Newer posts'.
  #     :screen_reader_text Screen reader text for nav element.
  #                         Default 'Posts navigation'.
  # }
  # @return [string] Markup for posts links.
  def get_the_posts_navigation( args = {} )
    navigation = ''

    # Don't print empty markup if there's only one page.
    if true # ?? ( $GLOBALS['wp_query']->max_num_pages > 1 )
      args = wp_parse_args(
          args,
          {
              prev_text:	  t('railspress.post.index.older'),
              next_text:	  t( 'railspress.post.index.newer'),
              screen_reader_text:	 t('railspress.post.index.navigation'),
          }
      )

      next_link = get_previous_posts_link( args[:next_text] )
      prev_link = get_next_posts_link( args[:prev_text] )

      navigation += '<div class="nav-previous">' + prev_link + '</div>' if prev_link
      navigation += '<div class="nav-next">'     + next_link + '</div>' if  next_link

      navigation = _navigation_markup( navigation, 'posts-navigation', args[:screen_reader_text] )
    end
    navigation
  end

  # Displays the navigation to next/previous set of posts, when applicable.
  #
  # @param [array] args Optional. See get_the_posts_navigation() for available arguments.
  #                     Default empty array.
  def the_posts_navigation( args = {} )
    get_the_posts_navigation( args )
  end

  # Retrieves a paginated navigation to next/previous set of posts, when applicable.
  #
  # @param [array] $args {
  #     Optional. Default pagination arguments, see paginate_links().
  #
  #     @type string $screen_reader_text Screen reader text for navigation element.
  #                                      Default 'Posts navigation'.
  # }
  # @return [string] Markup for pagination links.
  def get_the_posts_pagination(args = {})
    navigation = ''

    # Don't print empty markup if there's only one page.
    if true # ?? ( $GLOBALS['wp_query']->max_num_pages > 1 )
      args = wp_parse_args(
          args,
          {
              mid_size: 1,
              prev_text: t( 'railspress.post.show.prev' ), # 'previous set of posts'
              next_text: t( 'railspress.post.show.next' ), # 'next set of posts'
              screen_reader_text: t( 'railspress.post.show.navigation' ),
          }
      )

      # Make sure we get a string back. Plain is the next best thing.
      if 'array' == args['type']
          args['type'] = 'plain'
      end

      # Set up paginated links.
      links = paginate_links( args )

      navigation = _navigation_markup( links, 'pagination', args[:screen_reader_text] ) if links
      end

      navigation
    end

    # Displays a paginated navigation to next/previous set of posts, when applicable.
    #
    # @param [array] args Optional. See get_the_posts_pagination() for available arguments.
    #                     Default empty array.
    def the_posts_pagination( args = {} )
      get_the_posts_pagination( args )
    end

  # Wraps passed links in navigational markup.
  #
  # @param [string] links              Navigational links.
  # @param [string] nav_class          Optional. Custom class for nav element. Default: 'posts-navigation'.
  # @param [string] screen_reader_text Optional. Screen reader text for nav element. Default: 'Posts navigation'.
  # @return [string] Navigation template tag.
  def _navigation_markup( links, nav_class = 'posts-navigation', screen_reader_text = '' )
    screen_reader_text = t( 'railspress.post.show.navigation' ) if screen_reader_text.blank?

      template = '
	<nav class="navigation %1$s" role="navigation">
		<h2 class="screen-reader-text">%2$s</h2>
		<div class="nav-links">%3$s</div>
	</nav>'

    # Filters the navigation markup template.
    #
    # Note: The filtered template HTML must contain specifiers for the navigation
    # class (%1$s), the screen-reader-text value (%2$s), and placement of the
    # navigation links (%3$s):
    #
    #     <nav class="navigation %1$s" role="navigation">
    #         <h2 class="screen-reader-text">%2$s</h2>
    #         <div class="nav-links">%3$s</div>
    #     </nav>
    #
    # @param string $template The default template.
    # @param string $class    The class passed by the calling function.
    # @return string Navigation template.
    template = apply_filters( 'navigation_markup_template', template, nav_class )

    sprintf( template, sanitize_html_class( nav_class ), esc_html( screen_reader_text ), links )
  end

  # TODO get_comments_pagenum_link, get_next_comments_link, next_comments_link, get_previous_comments_link, previous_comments_link, paginate_comments_links, get_the_comments_navigation, the_comments_navigation, get_the_comments_pagination, the_comments_pagination

  # Retrieves the URL for the current site where the front end is accessible.
  #
  # Returns the 'home' option with the appropriate protocol. The protocol will be 'https'
  # if is_ssl() evaluates to true; otherwise, it will be the same as the 'home' option.
  # If `$scheme` is 'http' or 'https', is_ssl() is overridden.
  #
  # @param  [string]      path   Optional. Path relative to the home URL. Default empty.
  # @param  [string|null] scheme Optional. Scheme to give the home URL context. Accepts
  #                              'http', 'https', 'relative', 'rest', or null. Default null.
  # @return [string] Home URL link with optional path appended.
  def home_url(path = '', scheme = nil)
    get_home_url(nil, path, scheme )
  end

  # Retrieves the URL for a given site where the front end is accessible.
  #
  # Returns the 'home' option with the appropriate protocol. The protocol will be 'https'
  # if is_ssl() evaluates to true; otherwise, it will be the same as the 'home' option.
  # If `$scheme` is 'http' or 'https', is_ssl() is overridden.
  #
  # @global string $pagenow
  #
  # @param  [int]         blog_id Optional. Site ID. Default null (current site).
  # @param  [string]      path    Optional. Path relative to the home URL. Default empty.
  # @param  [string|null] scheme  Optional. Scheme to give the home URL context. Accepts
  #                               'http', 'https', 'relative', 'rest', or null. Default null.
  # @return [string] Home URL link with optional path appended.
  def get_home_url(blog_id = nil, path = '', scheme = nil)
    orig_scheme = scheme

    if blog_id.blank? || !is_multisite
      url = get_option('home')
    else
      switch_to_blog(blog_id)
      url = get_option('home')
      restore_current_blog()
    end

    # TODO
    # unless ['http', 'https', 'relative'].include?(scheme)
    #   if is_ssl() && !is_admin() && 'wp-login.php' != pagenow
    #     scheme = 'https'
    #   else
    #     scheme = parse_url(url, PHP_URL_SCHEME)
    #   end
    # end

    url = set_url_scheme(url, scheme)

    if !path.blank? && path.is_a?(String)
      url += '/' + path.gsub(/^\//, '')
    end

    # Filters the home URL.
    apply_filters('home_url', url, path, orig_scheme, blog_id)
  end

  # Retrieves the URL for the current site where WordPress application files
  # (e.g. wp-blog-header.php or the wp-admin/ folder) are accessible.
  #
  # Returns the 'site_url' option with the appropriate protocol, 'https' if
  # is_ssl() and 'http' otherwise. If $scheme is 'http' or 'https', is_ssl() is
  # overridden.
  #
  # @param [string] path   Optional. Path relative to the site URL. Default empty.
  # @param [string] scheme Optional. Scheme to give the site URL context. See set_url_scheme().
  # @return [string] Site URL link with optional path appended.
  def site_url(path = '', scheme = nil )
    get_site_url(nil, path, scheme )
  end

  # Retrieves the URL for a given site where WordPress application files
  # (e.g. wp-blog-header.php or the wp-admin/ folder) are accessible.
  #
  # Returns the 'site_url' option with the appropriate protocol, 'https' if
  # is_ssl() and 'http' otherwise. If `$scheme` is 'http' or 'https',
  # `is_ssl()` is overridden.
  #
  # @param [int]    blog_id Optional. Site ID. Default null (current site).
  # @param [string] path    Optional. Path relative to the site URL. Default empty.
  # @param [string] scheme  Optional. Scheme to give the site URL context. Accepts
  #                         'http', 'https', 'login', 'login_post', 'admin', or
  #                         'relative'. Default null.
  # @return string Site URL link with optional path appended.
  def get_site_url(blog_id = nil, path = '', scheme = nil )
    if  blog_id.blank? || !is_multisite
      url = get_option('siteurl')
    else
      switch_to_blog blog_id
      url = get_option('siteurl')
      restore_current_blog
    end

    url = set_url_scheme(url, scheme )

    url += '/' + path.gsub(/^\//, '') if path.is_a?(String)

    # Filters the site URL.
    #
    # @param string      $url     The complete site URL including scheme and path.
    # @param string      $path    Path relative to the site URL. Blank string if no path is specified.
    # @param string|null $scheme  Scheme to give the site URL context. Accepts 'http', 'https', 'login',
    #                             'login_post', 'admin', 'relative' or null.
    # @param int|null    $blog_id Site ID, or null for the current site.
    apply_filters( 'site_url', url, path, scheme, blog_id )
  end

  # Retrieves the URL to the admin area for the current site.
  #
  # @since 2.6.0
  #
  # @param [string] path   Optional path relative to the admin URL.
  # @param [string] scheme The scheme to use. Default is 'admin', which obeys force_ssl_admin() and is_ssl().
  #                       'http' or 'https' can be passed to force those schemes.
  # @return [string] Admin URL link with optional path appended.
  def admin_url( path = '', scheme = 'admin' )
    get_admin_url( nil, path, scheme)
  end

  # Retrieves the URL to the admin area for a given site.
  #
  # @param [int]    blog_id Optional. Site ID. Default null (current site).
  # @param [string] path    Optional. Path relative to the admin URL. Default empty.
  # @param [string] scheme  Optional. The scheme to use. Accepts 'http' or 'https',
  #                         to force those schemes. Default 'admin', which obeys
  #                         force_ssl_admin() and is_ssl().
  # @return [string] Admin URL link with optional path appended.
  def get_admin_url(blog_id = nil, path = '', scheme = 'admin')
    url = get_site_url(blog_id, 'wp-admin/', scheme )

    url += path.gsub(/^\//, '') if path.is_a?(String)

    # Filters the admin area URL.
    #
    # @param [string]   url     The complete admin area URL including scheme and path.
    # @param [string]   path    Path relative to the admin area URL. Blank string if no path is specified.
    # @param [int|null] blog_id Site ID, or null for the current site.
    apply_filters('admin_url', url, path, blog_id)
  end

  # Retrieves the URL to the includes directory.
  #
  # @since 2.6.0
  #
  # @param [string] path   Optional. Path relative to the includes URL. Default empty.
  # @param [string] scheme Optional. Scheme to give the includes URL context. Accepts
  #                        'http', 'https', or 'relative'. Default null.
  # @return [string] Includes URL link with optional path appended.
  def includes_url( path = '', scheme = nil )
    url = site_url( '/' + Railspress.WPINC + '/', scheme )

    url += path.gsub(/^\//, '') if path.is_a? String

    # Filters the URL to the includes directory.
    #
    # @param string $url  The complete URL to the includes directory including scheme and path.
    # @param string $path Path relative to the URL to the wp-includes directory. Blank string
    #                     if no path is specified.
    apply_filters('includes_url', url, path )
  end

  # Retrieves the URL to the content directory.
  #
  # @param [string] path Optional. Path relative to the content URL. Default empty.
  # @return string Content URL link with optional path appended.
  def content_url(path = '')
    url = set_url_scheme( Railspress.WP_CONTENT_URL )

    url += '/' + path.gsub(/^\//, '') if path.is_a? String

    # Filters the URL to the content directory.
    apply_filters( 'content_url', url, path )
  end

  # Sets the scheme for a URL.
  #
  # @param [string]      url    Absolute URL that includes a scheme
  # @param [string|null] scheme Optional. Scheme to give $url. Currently 'http', 'https', 'login',
  #                             'login_post', 'admin', 'relative', 'rest', 'rpc', or null. Default null.
  # @return [string] url URL with chosen scheme.
  def set_url_scheme(url, scheme = nil )
    orig_scheme = scheme

    if scheme.blank?
      scheme = is_ssl ? 'https' : 'http'
    elsif scheme == 'admin' || scheme == 'login' || scheme == 'login_post' || scheme == 'rpc'
      scheme = is_ssl || force_ssl_admin() ? 'https' : 'http'
    elsif scheme != 'http' && scheme != 'https' && scheme != 'relative'
    scheme = is_ssl ? 'https' : 'http';
    end

    url = url.strip
    url = 'http:' + url if url.start_with?('//')

    if 'relative' == scheme
      url = url.gsub(/^\w+:\/\/[^\/]*/, '').lstrip
      if url != '' && url[0] == '/'
        url = '/' + ltrim( url, "/ \t\n\r\0\x0B" )
      end
    else
      url = url.gsub(/^\w+:\/\//, scheme + '://')
    end

    # Filters the resulting URL after setting the scheme.
    #
    # @since 3.4.0
    #
    # @param string      $url         The complete URL including scheme and path.
    # @param string      $scheme      Scheme applied to the URL. One of 'http', 'https', or 'relative'.
    # @param string|null $orig_scheme Scheme requested for the URL. One of 'http', 'https', 'login',
    #                                 'login_post', 'admin', 'relative', 'rest', 'rpc', or null.
    apply_filters( 'set_url_scheme', url, scheme, orig_scheme )
  end


end