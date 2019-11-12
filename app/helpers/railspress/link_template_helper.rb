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
    if GLOBAL.wp_rewrite.use_trailing_slashes
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

    if  post.is_a?(Railspress::WpPost) && 'sample' == post.filter
      sample = true
    else
      post   = get_post( post )
      sample = false
    end

    if post.id.blank?
      return false
    end
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
      # TODO continue with post...
      # date           = explode( ' ', date( 'Y m d H i s', $unixtime ) );
      # 		rewritereplace = [
      # 			date[0],
      # 			date[1],
      # 			date[2],
      # 			date[3],
      # 			date[4],
      # 			date[5],
      # 			post->post_name,
      # 			post->ID,
      # 			category,
      # 			author,
      # 			post->post_name,
      # 		]
      # $permalink      = home_url( str_replace( $rewritecode, $rewritereplace, $permalink ) );
      permalink      = user_trailingslashit(permalink, 'single')
    else # if they're not using the fancy permalink option
  		permalink = main_app.root_url + '?p=' + post.id
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

    post_link = GLOBAL.wp_rewrite.get_extra_permastruct( post.post_type )

    slug = post.post_name

    draft_or_pending = get_post_status(post) && ['draft', 'pending', 'auto-draft', 'future'].include?( get_post_status(post))

    post_type = get_post_type_object(post.post_type)

    if post_type.hierarchical
        slug = get_page_uri(post)
    end

    if ( ! post_link.blank? && ( ! draft_or_pending || sample ) )
        unless leavename
            post_link = post_link.gsub( '%' + post.post_type + '%', slug)
        end
        post_link = home_url( user_trailingslashit( post_link ) )
        else
            if post_type.query_var && ( isset( $post.post_status ) && ! draft_or_pending )
                post_link = add_query_arg( post_type.query_var, slug, '' )
            else
                post_link = add_query_arg(
                    {
                        'post_type' => post.post_type,
                        'p'         => post.id,
                    },
                    ''
                )
            end
            post_link = home_url(post_link)
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
    link = GLOBAL.wp_rewrite.get_page_permastruct

    if !link.blank? && ((!post.post_status.blank? && !draft_or_pending) || sample)
      unless leavename
        link = link.gsub('%pagename%', get_page_uri(post))
      end
      link = show_page_path(slug: link) # TODO or this root_path + link
      link = user_trailingslashit(link, 'page')
    else
      link = main_app.root_path(page_id: post.id)
    end

    # Filters the permalink for a non-page_on_front page.
    apply_filters('_get_page_link', link, post.id)
  end

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

    if blog_id.blank? || true # !is_multisite()
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

    # TODO url = set_url_scheme(url, scheme)

    if !path.blank? && path.is_a?(String)
      url += '/' + path.gsub(/^\//, '')
    end

    # Filters the home URL.
    apply_filters('home_url', url, path, orig_scheme, blog_id)
  end

end