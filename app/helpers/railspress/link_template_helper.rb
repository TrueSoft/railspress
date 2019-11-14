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

    post_link = Railspress.GLOBAL.wp_rewrite.get_extra_permastruct( post.post_type )

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
    link = Railspress.GLOBAL.wp_rewrite.get_page_permastruct

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

    url.strip!
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