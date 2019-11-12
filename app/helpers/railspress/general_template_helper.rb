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
  # @param string show Optional. Site information to display. Default empty.
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

  # TODO get_site_icon_url, site_icon_url, has_site_icon

  # Determines whether the site has a custom logo.
  #
  # @param [int] blog_id Optional. ID of the blog in question. Default is the ID of the current blog.
  # @return bool Whether the site has a custom logo or not.
  def has_custom_logo(blog_id = 0)
    switched_blog = false

    if ( false && is_multisite() && !blog_id.blank? && blog_id.to_i != get_current_blog_id())
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

    if ( false && is_multisite() && !blog_id.blank? && blog_id.to_i != get_current_blog_id())
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
      html = sprintf(
          '<a href="%1$s" class="custom-logo-link" rel="home">%2$s</a>',
          esc_url( home_url( '/' ) ),
          wp_get_attachment_image( custom_logo_id, 'full', false, custom_logo_attr )
      )
    elsif false # TODO is_customize_preview
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

end