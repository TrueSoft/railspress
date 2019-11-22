=begin
 * General template tags that can go anywhere in a template.
 *
 * file wp-includes\general-template.php
=end
module Railspress::GeneralTemplateHelper


  # Displays information about the current site.
  #
  # @see get_bloginfo() For possible `$show` values
  #
  # @param [string] show Optional. Site information to display. Default empty.
  def bloginfo(show = '')
    get_bloginfo(show, 'display')
  end

  # Retrieves information about the current site.
  #
  # Possible values for `$show` include:
  #
  # - 'name' - Site title (set in Settings > General)
  # - 'description' - Site tagline (set in Settings > General)
  # - 'wpurl' - The WordPress address (URL) (set in Settings > General)
  # - 'url' - The Site address (URL) (set in Settings > General)
  # - 'admin_email' - Admin email (set in Settings > General)
  # - 'charset' - The "Encoding for pages and feeds"  (set in Settings > Reading)
  # - 'version' - The current WordPress version
  # - 'html_type' - The content-type (default: "text/html"). Themes and plugins
  #   can override the default value using the {@see 'pre_option_html_type'} filter
  # - 'text_direction' - The text direction determined by the site's language. is_rtl()
  #   should be used instead
  # - 'language' - Language code for the current site
  # - 'stylesheet_url' - URL to the stylesheet for the active theme. An active child theme
  #   will take precedence over this value
  # - 'stylesheet_directory' - Directory path for the active theme.  An active child theme
  #   will take precedence over this value
  # - 'template_url' / 'template_directory' - URL of the active theme's directory. An active
  #   child theme will NOT take precedence over this value
  # - 'pingback_url' - The pingback XML-RPC file URL (xmlrpc.php)
  # - 'atom_url' - The Atom feed URL (/feed/atom)
  # - 'rdf_url' - The RDF/RSS 1.0 feed URL (/feed/rdf)
  # - 'rss_url' - The RSS 0.92 feed URL (/feed/rss)
  # - 'rss2_url' - The RSS 2.0 feed URL (/feed)
  # - 'comments_atom_url' - The comments Atom feed URL (/comments/feed)
  # - 'comments_rss2_url' - The comments RSS 2.0 feed URL (/comments/feed)
  #
  # Some `$show` values are deprecated and will be removed in future versions.
  # These options will trigger the _deprecated_argument() function.
  #
  # Deprecated arguments include:
  #
  # - 'siteurl' - Use 'url' instead
  # - 'home' - Use 'url' instead
  #
  # @since 0.71
  #
  # @global string $wp_version
  #
  # @param [string] show   Optional. Site info to retrieve. Default empty (site name).
  # @param [string] filter Optional. How to filter what is retrieved. Default 'raw'.
  # @return string Mostly string values, might be empty.
  def get_bloginfo(show = '', filter = 'raw')
    output = case show
             when 'home', 'siteurl' # DEPRECATED
               # Intentional fall-through to be handled by the 'url' case.
               home_url()
             when 'url'
               home_url()
             when 'wpurl'
               site_url()
             when 'description'
               get_option('blogdescription')
             when 'rdf_url'
               get_feed_link('rdf')
             when 'rss_url'
               get_feed_link('rss')
             when 'rss2_url'
               get_feed_link('rss2')
             when 'atom_url'
               get_feed_link('atom')
             when 'comments_atom_url'
               get_feed_link('comments_atom')
             when 'comments_rss2_url'
               get_feed_link('comments_rss2')
             when 'pingback_url'
               site_url('xmlrpc.php')
             when 'stylesheet_url'
               get_stylesheet_uri()
             when 'stylesheet_directory'
               get_stylesheet_directory_uri()
             when 'template_directory', 'template_url'
               get_template_directory_uri()
             when 'admin_email'
               get_option('admin_email')
             when 'charset'
               o = get_option('blog_charset')
               o.blank? ? 'UTF-8' : o
             when 'html_type'
               get_option('html_type')
             when 'version'
               Railspress::WP_VERSION
             when 'language'
               # translators: Translate this to the correct language tag for your locale,
               # see https://www.w3.org/International/articles/language-tags/ for reference.
               # Do not translate into your own language.
               o = __('html_lang_attribute')
               if o == 'html_lang_attribute' || o =~ /[^a-zA-Z0-9-]/
                 o = I18n.default_locale # determine_locale()
                 o.gsub('_', '-')
               else
                 o
               end
             when 'text_direction' # DEPRECATED
               if function_exists('is_rtl')
                 is_rtl() ? 'rtl' : 'ltr';
               else
                 'ltr'
               end
             when 'name'
               get_option('blogname')
             else
               get_option('blogname')
             end

    url = true
    if !show.include?('url') && !show.include?('directory') && !show.include?('home')
      url = false
    end

    if 'display' == filter
      if url
        # Filters the URL returned by get_bloginfo().
        output = apply_filters('bloginfo_url', output, show)
      else
        # Filters the site information returned by get_bloginfo().
        output = apply_filters('bloginfo', output, show)
      end
    end

    output
  end

  # Returns the Site Icon URL.
  #
  # @param [int]    size    Optional. Size of the site icon. Default 512 (pixels).
  # @param [string] url     Optional. Fallback url if no site icon is found. Defaultget_stylesheet_uri empty.
  # @param [int]    blog_id Optional. ID of the blog to get the site icon for. Default current blog.
  # @return string Site Icon URL.
  def get_site_icon_url(size = 512, url = '', blog_id = 0 )
    switched_blog = false

    if is_multisite && !blog_id.blank? && blog_id.to_i != get_current_blog_id()
      switch_to_blog( blog_id )
      switched_blog = true
    end

    site_icon_id = get_option( 'site_icon' )

    if site_icon_id && site_icon_id != '0'
      if size >= 512
        size_data = 'full'
      else
        size_data = [size, size]
      end
      url = wp_get_attachment_image_url(site_icon_id, size_data)
    end

    # restore_current_blog if switched_blog

    # Filters the site icon URL.
    apply_filters( 'get_site_icon_url', url, size, blog_id )
  end

  # Displays the Site Icon URL.
  # @param [int]    size    Optional. Size of the site icon. Default 512 (pixels).
  # @param [string] url     Optional. Fallback url if no site icon is found. Default empty.
  # @param [int]    blog_id Optional. ID of the blog to get the site icon for. Default current blog.
  def site_icon_url(size = 512, url = '', blog_id = 0)
    esc_url(get_site_icon_url(size, url, blog_id ))
  end

  # Whether the site has a Site Icon.
  #
  # @param [int] blog_id Optional. ID of the blog in question. Default current blog.
  # @return bool Whether the site has a site icon or not.
  def has_site_icon( blog_id = 0 )
    !get_site_icon_url( 512, '', blog_id ).blank?
  end

  # Determines whether the site has a custom logo.
  #
  # @param [int] blog_id Optional. ID of the blog in question. Default is the ID of the current blog.
  # @return bool Whether the site has a custom logo or not.
  def has_custom_logo(blog_id = 0)
    switched_blog = false

    if is_multisite && !blog_id.blank? && blog_id.to_i != get_current_blog_id()
      switch_to_blog( blog_id )
      switched_blog = true
    end

    custom_logo_id = get_theme_mod('custom_logo')

    restore_current_blog if switched_blog

    !custom_logo_id.blank?
  end

  # Returns a custom logo, linked to home.
  #
  # @param [int] blog_id Optional. ID of the blog in question. Default is the ID of the current blog.
  # @return [string] Custom logo markup.
  def get_custom_logo(blog_id = 0 )
    html          = ''
    switched_blog = false

    if is_multisite && !blog_id.blank? && blog_id.to_i != get_current_blog_id()
      switch_to_blog( blog_id )
      switched_blog = true
    end

    custom_logo_id = get_theme_mod( 'custom_logo' )

    # We have a logo. Logo is go.
    if custom_logo_id
      custom_logo_attr = {class: 'custom-logo'}

      # If the logo alt attribute is empty, get the site title and explicitly
      # pass it to the attributes used by wp_get_attachment_image().
      image_alt = get_post_meta(custom_logo_id, '_wp_attachment_image_alt', true )
      if image_alt.blank?
        custom_logo_attr[:alt] = get_bloginfo('name','display')
      end

      # If the alt attribute is not empty, there's no need to explicitly pass
      # it because wp_get_attachment_image() already adds the alt attribute.
      html = sprintf('<a href="%1$s" class="custom-logo-link" rel="home">%2$s</a>',
          esc_url( home_url( '/' ) ),
          wp_get_attachment_image( custom_logo_id, 'full', false, custom_logo_attr ) )
    elsif is_customize_preview
      # If no logo is set but we're in the Customizer, leave a placeholder (needed for the live preview).
      '<a href="' + esc_url( home_url( '/' ) )+'" class="custom-logo-link" style="display:none;"><img class="custom-logo"/></a>'
    end

    restore_current_blog if switched_blog

    # Filters the custom logo output.
    apply_filters('get_custom_logo', html, blog_id)
  end

  # Displays a custom logo, linked to home.
  #
  # @param [int] blog_id Optional. ID of the blog in question. Default is the ID of the current blog.
  def the_custom_logo(blog_id = 0)
    get_custom_logo(blog_id)
  end

  # TODO wp_get_document_title, _wp_render_title_tag, wp_title, single_post_title, post_type_archive_title, single_cat_title, ...

  # Fire the wp_head action.
  def wp_head
    # Prints scripts or data in the head tag on the front end.
    do_action 'wp_head' 
  end
  
  # Fire the wp_footer action.
  def wp_footer
    # Prints scripts or data before the closing body tag on the front end.
    do_action 'wp_footer' 
  end
  
  # Fire the wp_body_open action.
  def wp_body_open
    # Triggered after the opening <body> tag.
    do_action  'wp_body_open'
  end

  # TODO feed_links feed_links_extra rsd_link wlwmanifest_link 

  # Displays a noindex meta tag if required by the blog configuration.
  #
  # If a blog is marked as not being public then the noindex meta tag will be
  # output to tell web robots not to index the page content. Add this to the
  # {@see 'wp_head'} action.
  #
  # Typical usage is as a {@see 'wp_head'} callback:
  #
  #     add_action( 'wp_head', 'noindex' );
  #
  # @see wp_no_robots
  def noindex()
    # If the blog is not public, tell robots to go away.
    wp_no_robots() if ( '0' == get_option( 'blog_public' ) )
  end

  # Display a noindex meta tag.
  #
  # Outputs a noindex meta tag that tells web robots not to index the page content.
  # Typical usage is as a wp_head callback. add_action( 'wp_head', 'wp_no_robots' );
  def wp_no_robots()
    "<meta name='robots' content='noindex,follow' />\n"
  end

  # Display a noindex,noarchive meta tag and referrer origin-when-cross-origin meta tag.
  #
  # Outputs a noindex,noarchive meta tag that tells web robots not to index or cache the page content.
  # Outputs a referrer origin-when-cross-origin meta tag that tells the browser not to send the full
  # url as a referrer to other sites when cross-origin assets are loaded.
  #
  # Typical usage is as a wp_head callback. add_action( 'wp_head', 'wp_sensitive_page_meta' );
  def wp_sensitive_page_meta()
    "<meta name='robots' content='noindex,noarchive' />
    <meta name='referrer' content='strict-origin-when-cross-origin' />"
  end

# Display site icon meta tags.
#
# @link https://www.whatwg.org/specs/web-apps/current-work/multipage/links.html#rel-icon HTML5 specification link icon.
def wp_site_icon() 
  return if ! has_site_icon() && ! is_customize_preview

  meta_tags = []
  icon_32   = get_site_icon_url( 32 )
  if icon_32.blank? && is_customize_preview
    icon_32 = '/favicon.ico'; # Serve default favicon URL in customizer so element can be updated for preview.
  end
  if icon_32 
    meta_tags << sprintf( '<link rel="icon" href="%s" sizes="32x32" />', esc_url( icon_32 ) )
  end
  icon_192 = get_site_icon_url( 192 )
  if  icon_192 
    meta_tags << sprintf( '<link rel="icon" href="%s" sizes="192x192" />', esc_url( icon_192 ) )
  end
  icon_180 = get_site_icon_url( 180 )
  if  icon_180 
    meta_tags << sprintf( '<link rel="apple-touch-icon-precomposed" href="%s" />', esc_url( icon_180 ) )
  end
  icon_270 = get_site_icon_url( 270 )
  if icon_270 
    meta_tags << sprintf( '<meta name="msapplication-TileImage" content="%s" />', esc_url( icon_270 ) )
  end

  # Filters the site icon meta tags, so plugins can add their own.
  meta_tags = apply_filters( 'site_icon_meta_tags', meta_tags )
  # TODO meta_tags = array_filter( meta_tags )

  output = ''
  meta_tags.each do |meta_tag|
    output << meta_tag + '\n'
  end
end

  # TODO wp_resource_hints wp_dependencies_unique_hosts user_can_richedit wp_default_editor wp_editor ...

  # Displays the URL of a WordPress admin CSS file.
  #
  # @see WP_Styles::_css_href and its {@see 'style_loader_src'} filter.
  #
  # @param [string] file file relative to wp-admin/ without its ".css" extension.
  # @return string
  def wp_admin_css_uri( file = 'wp-admin' )
    if defined( 'WP_INSTALLING' )
      _file = "./#{file}.css"
    else
      _file = admin_url( "#{file}.css" )
    end
    _file = add_query_arg( 'version', get_bloginfo( 'version' ), _file )

    # Filters the URI of a WordPress admin CSS file.
    apply_filters( 'wp_admin_css_uri', _file, file )
  end

  # Enqueues or directly prints a stylesheet link to the specified CSS file.
  #
  # "Intelligently" decides to enqueue or to print the CSS file. If the
  # {@see 'wp_print_styles'} action has *not* yet been called, the CSS file will be
  # enqueued. If the {@see 'wp_print_styles'} action has been called, the CSS link will
  # be printed. Printing may be forced by passing true as the $force_echo
  # (second) parameter.
  #
  # For backward compatibility with WordPress 2.3 calling method: If the $file
  # (first) parameter does not correspond to a registered CSS file, we assume
  # $file is a file relative to wp-admin/ without its ".css" extension. A
  # stylesheet link to that generated URL is printed.
  #
  # @param [string] file       Optional. Style handle name or file name (without ".css" extension) relative
  #                            to wp-admin/. Defaults to 'wp-admin'.
  # @param [bool]   force_echo Optional. Force the stylesheet link to be printed rather than enqueued.
  def wp_admin_css( file = 'wp-admin', force_echo = false )
    # For backward compatibility
=begin TODO continue...
  handle = 0 == strpos( file, 'css/' ) ? substr( file, 4 ) : file

  if ( wp_styles()->query( $handle ) ) 
    if ( $force_echo || did_action( 'wp_print_styles' ) ) # we already printed the style queue. Print this one immediately
      wp_print_styles( $handle )
    else # Add to style queue
      wp_enqueue_style( $handle )
    end
    return
  end
=end
  # Filters the stylesheet link to the specified CSS file.
  apply_filters( 'wp_admin_css', "<link rel='stylesheet' href='" + esc_url( wp_admin_css_uri( file ) ) + "' type='text/css' />\n", file )

    if ( function_exists( 'is_rtl' ) && is_rtl() )
      # This filter is documented in wp-includes/general-template.php
      apply_filters( 'wp_admin_css', "<link rel='stylesheet' href='" . esc_url( wp_admin_css_uri( "#{file}-rtl" ) ) + "' type='text/css' />\n", "#{file}-rtl" )
    end
  end

end