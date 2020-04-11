=begin
 * WordPress Post Template Functions.
 *
 * Gets content for the current post in the loop.
 *
 * file wp-includes\post-template.php
=end
module Railspress::PostTemplateHelper
  include Railspress::TaxonomyLib

  # Display the ID of the current item in the WordPress Loop.
  def the_ID
    print get_the_ID
  end

  # Retrieve the ID of the current item in the WordPress Loop.
  #
  # @return [int|false] The ID of the current item in the WordPress Loop. False if $post is not set.
  def get_the_ID
    post = get_post
    post.nil? ? false : post.id
  end

  # Display or retrieve the current post title with optional markup.
  #
  # @param [string] $before Optional. Markup to prepend to the title. Default empty.
  # @param [string] $after  Optional. Markup to append to the title. Default empty.
  # @param [bool]   $echo   Optional. Whether to echo or return the title. Default true for echo.
  # @return [string|void] Current post title if $echo is false.
  def the_title(before = '', after = '', echo = true)
    title = get_the_title

    return if title.blank?

    title = before + title + after

    if echo
      print title
    else
      return title
    end
  end

  # Sanitize the current title when retrieving or displaying.
  #
  # Works like the_title(), except the parameters can be in a string or
  # an array. See the function for what can be override in the $args parameter.
  #
  # The title before it is displayed will have the tags stripped and esc_attr()
  # before it is passed to the user or displayed. The default as with the_title(),
  # is to display the title.
  #
  # @param [string|array] args {
  #     Title attribute arguments. Optional.
  #
  #     @type string  :before Markup to prepend to the title. Default empty.
  #     @type string  :after  Markup to append to the title. Default empty.
  #     @type bool    :echo   Whether to echo or return the title. Default true for echo.
  #     @type WP_Post :post   Current post object to retrieve the title for.
  # }
  # @return string|void String when echo is false.
  def the_title_attribute(args = '')
    defaults = {
        before: '',
        after: '',
        echo: true,
        post: get_post(),
    }
    r = Railspress::Functions.wp_parse_args(args, defaults)

    title = get_the_title(r[:post])

    return if title.blank?

    title = r[:before] + title + r[:after]
    title = esc_attr(strip_tags(title))

    if r[:echo]
      print title
    else
      return title
    end
  end

  # Retrieve post title.
  #
  # If the post is protected and the visitor is not an admin, then "Protected"
  # will be displayed before the post title. If the post is private, then
  # "Private" will be located before the post title.
  #
  # @param [int|WP_Post] post Optional. Post ID or WP_Post object. Default is global $post.
  # @return string
  def get_the_title(post = 0)
	  post = get_post(post)

  	title = post.post_title || ''
	  id    = post.id || 0

    unless is_admin
      if !post.post_password.blank?
        # Filters the text prepended to the post title for protected posts.
        #
        # The filter is only applied on the front end.
        protected_title_format = apply_filters('protected_title_format', 'railspress.post.show.title_protected', post)
        title = t(protected_title_format, title: title)
      elsif 'private' == post.post_status
        # Filters the text prepended to the post title of private posts.
        #
        # The filter is only applied on the front end.
        private_title_format = apply_filters('private_title_format', 'railspress.post.show.title_private', post)
        title = sprintf(private_title_format, title)
        title = t(private_title_format, title: title)
      end
    end

    # Filters the post title.
    apply_filters('the_title', title, id)
  end

  # Display the Post Global Unique Identifier (guid).
  #
  # The guid will appear to be a link, but should not be used as a link to the
  # post. The reason you should not use it as a link, is because of moving the
  # blog across domains.
  #
  # URL is escaped to make it XML-safe.
  #
  # @param [int|WP_Post] post Optional. Post ID or post object. Default is global $post.
  def the_guid(post = 0)
    post = get_post(post)

    guid = post.guid.nil? ? '' : get_the_guid(post)
    id = post.nil? ? 0 : post.id

    # Filters the escaped Global Unique Identifier (guid) of the post.
    apply_filters('the_guid', guid, id)
  end

  # Retrieve the Post Global Unique Identifier (guid).
  #
  # The guid will appear to be a link, but should not be used as an link to the
  # post. The reason you should not use it as a link, is because of moving the
  # blog across domains.
  #
  # @param [int|WP_Post] post Optional. Post ID or post object. Default is global $post.
  # @return string
  def get_the_guid(post = 0)
    post = get_post(post)

    guid = post.guid || ''
    id = post.id || 0

    # Filters the Global Unique Identifier (guid) of the post.
    apply_filters('get_the_guid', guid, id)
  end

  # Retrieves an array of the class names for the post container element.
  #
  # The class names are many. If the post is a sticky, then the 'sticky'
  # class name. The class 'hentry' is always added to each post. If the post has a
  # post thumbnail, 'has-post-thumbnail' is added as a class. For each taxonomy that
  # the post belongs to, a class will be added of the format '{$taxonomy}-{$slug}' -
  # eg 'category-foo' or 'my_custom_taxonomy-bar'.
  #
  # The 'post_tag' taxonomy is a special
  # case; the class has the 'tag-' prefix instead of 'post_tag-'. All class names are
  # passed through the filter, {@see 'post_class'}, with the list of class names, followed by
  # $class parameter value, with the post ID as the last parameter.
  #
  # @param [string|string[]] $class   Space-separated string or array of class names to add to the class list.
  # @param [int|WP_Post]     $post_id Optional. Post ID or post object.
  # @return [string[]] Array of class names.
  def get_post_class(clazz = '', post_id = nil)
    post = get_post(post_id)
    classes = []

    if clazz
      clazz = clazz.split(/\s+/) unless clazz.is_a? Array
      classes = clazz.map(&method(:esc_attr))
    else
      # Ensure that we always coerce class to being an array.
      clazz = []
    end


    classes << "post-#{post.ID}"
    classes << post.post_type unless is_admin

    classes << 'type-' + post.post_type
    classes << 'status-' + post.post_status

    # Post Format
    if post_type_supports(post.post_type, 'post-formats')
       post_format = get_post_format(post.ID)

      if post_format && !(post_format.is_a? Railspress::WP_Error)
        classes << 'format-' + sanitize_html_class(post_format)
      else
        classes << 'format-standard';
      end
    end

    # $post_password_required = post_password_required( $post->ID );
    #
    # # Post requires password.
    #     if ( $post_password_required ) {
    #       $classes[] = 'post-password-required';
    #     } elseif ( ! empty( $post->post_password ) ) {
    #   $classes[] = 'post-password-protected';
    # }
    #
    # Post thumbnails.
    #     if ( current_theme_supports( 'post-thumbnails' ) && has_post_thumbnail( $post->ID ) && ! is_attachment( $post ) && ! $post_password_required )
    #       classes << 'has-post-thumbnail'
    #     end
    #
    # sticky for Sticky Posts
    #             if ( is_sticky( $post->ID ) ) {
    #                 if ( is_home() && ! is_paged() ) {
    #                   $classes[] = 'sticky';
    #                 } elseif ( is_admin() ) {
    #                   $classes[] = 'status-sticky';
    #                 }
    #             }

    # hentry for hAtom compliance
    classes << 'hentry'

    # All public taxonomies
    taxonomies = get_taxonomies # TODO why? (public: true)
    taxonomies.each do |taxonomy|
      if is_object_in_taxonomy(post.post_type, taxonomy)
        get_the_terms(post.ID, taxonomy).each do |term|
          next if term.slug.blank?
          term_class = sanitize_html_class(term.slug, term.term_id)
          if (term_class.to_s =~ /^\d+(.\d+|\d*)$/) || term_class.gsub(/(^-)|(-$)/, '').blank?
            term_class = term.term_id
          end
          # 'post_tag' uses the 'tag' prefix for backward compatibility.
          if 'post_tag' == taxonomy
            classes << 'tag-' + term_class
          else
            classes << sanitize_html_class(taxonomy + '-' + term_class, taxonomy + '-' + term.term_id)
          end
        end
      end
    end

    # TODO Why entry is not added above?
    classes << 'entry'

    classes.map!(&method(:esc_attr))

    # Filters the list of CSS class names for the current post.
    classes = apply_filters('post_class', classes, clazz, post.ID)

    classes.uniq
  end


  # Displays the class names for the body element.
  #
  # @param [string|string[]] class_ Space-separated string or array of class names to add to the class list.
  def body_class( class_ = '' )
    # Separates class names with a single space, collates class names for body element
    'class="' + get_body_class( class_ ).join(' ') + '"'
  end

  # Retrieves an array of the class names for the body element.
  #
  # @global WP_Query $wp_query
  #
  # @param [string|string[]] class_ Space-separated string or array of class names to add to the class list.
  # @return string[] Array of class names.
  def get_body_class(class_ = '')
    # global $wp_query;

    classes = []

    # classes << 'rtl' if is_rtl()
    # classes << 'home' if is_front_page()
    # classes << 'blog' if is_home()
    # classes << 'privacy-policy' if is_privacy_policy()
    classes << 'archive' if !@archive.nil? # is_archive()
    # classes << 'date' if is_date()

    # TODO continue get_body_class

    if !class_.blank?
      class_ = class_.split(/\s+/) if !class_.is_a?(Array)
      classes += class_
    else
      # Ensure that we always coerce class to being an array.
      class_ = []
    end

    classes = classes.map(&method(:esc_attr))

    # Filters the list of CSS body class names for the current post or page.
    classes = apply_filters('body_class', classes, class_)
    classes.uniq
  end

  ##
  ## Page Template Functions for usage in Themes
  ##

  ##
  ## Post-meta: Custom per-post fields.
  ##

  ##
  ## Pages
  ##

  # Retrieve or display a list of pages (or hierarchical post type items) in list (li) format.
  #
  # @see get_pages()
  #
  # @param [array|string] args {
  #     Optional. Array or string of arguments to generate a list of pages. See `get_pages()` for additional arguments.
  #
  #     @type int          $child_of     Display only the sub-pages of a single page by ID. Default 0 (all pages).
  #     @type string       $authors      Comma-separated list of author IDs. Default empty (all authors).
  #     @type string       $date_format  PHP date format to use for the listed pages. Relies on the 'show_date' parameter.
  #                                      Default is the value of 'date_format' option.
  #     @type int          $depth        Number of levels in the hierarchy of pages to include in the generated list.
  #                                      Accepts -1 (any depth), 0 (all pages), 1 (top-level pages only), and n (pages to
  #                                      the given n depth). Default 0.
  #     @type bool         $echo         Whether or not to echo the list of pages. Default true.
  #     @type string       $exclude      Comma-separated list of page IDs to exclude. Default empty.
  #     @type array        $include      Comma-separated list of page IDs to include. Default empty.
  #     @type string       $link_after   Text or HTML to follow the page link label. Default null.
  #     @type string       $link_before  Text or HTML to precede the page link label. Default null.
  #     @type string       $post_type    Post type to query for. Default 'page'.
  #     @type string|array $post_status  Comma-separated list or array of post statuses to include. Default 'publish'.
  #     @type string       $show_date    Whether to display the page publish or modified date for each page. Accepts
  #                                      'modified' or any other value. An empty value hides the date. Default empty.
  #     @type string       $sort_column  Comma-separated list of column names to sort the pages by. Accepts 'post_author',
  #                                      'post_date', 'post_title', 'post_name', 'post_modified', 'post_modified_gmt',
  #                                      'menu_order', 'post_parent', 'ID', 'rand', or 'comment_count'. Default 'post_title'.
  #     @type string       $title_li     List heading. Passing a null or empty value will result in no heading, and the list
  #                                      will not be wrapped with unordered list `<ul>` tags. Default 'Pages'.
  #     @type string       $item_spacing Whether to preserve whitespace within the menu's HTML. Accepts 'preserve' or 'discard'.
  #                                      Default 'preserve'.
  #     @type Walker       $walker       Walker instance to use for listing pages. Default empty (Walker_Page).
  # }
  # @return string|void HTML list of pages.
  #/
  def wp_list_pages(args = '' )
    defaults = {
        depth:         0,
        show_date:     '',
        date_format:   get_option( 'date_format' ),
        child_of:      0,
        exclude:       '',
       # title_li:      __( 'Pages' ),
        echo:          1,
        authors:       '',
        sort_column:   'menu_order, post_title',
        link_before:   '',
        link_after:    '',
        item_spacing:  'preserve',
        walker:        ''
    }
    r = Railspress::Functions.wp_parse_args(args, defaults)

    unless ['preserve', 'discard'].include?(r[:item_spacing])
      # invalid value, fall back to default.
      r[:item_spacing] = defaults[:item_spacing]
    end

    output       = ''
    current_page = 0

    # TODO continue implement post-template.wp_list_pages()
    ''
  end

  # Displays or retrieves a list of pages with an optional home link.
  #
  # The arguments are listed below and part of the arguments are for wp_list_pages() function.
  # Check that function for more info on those arguments.
  #
  # @param [array|string] args {
  #     Optional. Array or string of arguments to generate a page menu. See `wp_list_pages()` for additional arguments.
  #
  #     @type string          $sort_column  How to sort the list of pages. Accepts post column names.
  #                                         Default 'menu_order, post_title'.
  #     @type string          $menu_id      ID for the div containing the page list. Default is empty string.
  #     @type string          $menu_class   Class to use for the element containing the page list. Default 'menu'.
  #     @type string          $container    Element to use for the element containing the page list. Default 'div'.
  #     @type bool            $echo         Whether to echo the list or return it. Accepts true (echo) or false (return).
  #                                         Default true.
  #     @type int|bool|string $show_home    Whether to display the link to the home page. Can just enter the text
  #                                         you'd like shown for the home link. 1|true defaults to 'Home'.
  #     @type string          $link_before  The HTML or text to prepend to $show_home text. Default empty.
  #     @type string          $link_after   The HTML or text to append to $show_home text. Default empty.
  #     @type string          $before       The HTML or text to prepend to the menu. Default is '<ul>'.
  #     @type string          $after        The HTML or text to append to the menu. Default is '</ul>'.
  #     @type string          $item_spacing Whether to preserve whitespace within the menu's HTML. Accepts 'preserve'
  #                                         or 'discard'. Default 'discard'.
  #     @type Walker          $walker       Walker instance to use for listing pages. Default empty (Walker_Page).
  # }
  # @return [string|void] HTML menu
  def wp_page_menu(args = {})
    defaults = {
        sort_column: 'menu_order, post_title',
        menu_id: '',
        menu_class: 'menu',
        container: 'div',
        echo: true,
        link_before: '',
        link_after: '',
        before: '<ul>',
        after: '</ul>',
        item_spacing: 'discard',
        walker: '',
    }
    args = Railspress::Functions.wp_parse_args(args, defaults)

    unless ['preserve', 'discard'].include?(args[:item_spacing])
      # invalid value, fall back to default.
      args[:item_spacing] = defaults[:item_spacing]
    end

    t, n = 'preserve' == args[:item_spacing] ? ["\t", "\n"] : ['', '']

    # Filters the arguments used to generate a page-based menu.
    args = apply_filters('wp_page_menu_args', args)

    menu = ''

    list_args = args

    # Show Home in the menu
    unless args[:show_home].blank?
      if true == args[:show_home] || '1' == args[:show_home] || 1 == args[:show_home]
        text = __('Home')
      else
        text = args[:show_home]
      end
      class_ = ''
      class_ = 'class="current_page_item"' if is_front_page() && !is_paged()

      menu += '<li ' + class_ + '><a href="' + home_url('/') + '">' + args['link_before'] + text + args[:link_after] + '</a></li>'
      # If the front page is a page, add it to the exclude list
      if get_option('show_on_front') == 'page'
        if !empty(list_args[:exclude])
          list_args[:exclude] += ','
        else
          list_args[:exclude] = ''
        end
        list_args[:exclude] += get_option('page_on_front')
      end
    end

    list_args[:echo] = false
    list_args[:title_li] = ''
    menu += wp_list_pages(list_args)

    container = sanitize_text_field(args[:container])

    # Fallback in case `wp_nav_menu()` was called without a container.
    container = 'div' if container.blank?

    if menu
      # wp_nav_menu doesn't set before and after
      if 'wp_page_menu' == args[:fallback_cb] && 'ul' != container
        args[:before] = "<ul>#{n}"
        args[:after] = '</ul>'
      end

      menu = args[:before] + menu + args[:after]
    end

    attrs = ''
    unless args[:menu_id].blank?
      attrs += ' id="' + esc_attr(args[:menu_id]) + '"'
    end

    unless args[:menu_class].blank?
      attrs += ' class="' + esc_attr(args[:menu_class]) + '"'
    end

    menu = "<#{container}#{attrs}>" + menu + "</#{container}>#{n}"

    # Filters the HTML output of a page-based menu.
    menu = apply_filters('wp_page_menu', menu, args)
    if (args[:echo])
      echo menu
    else
      return menu
    end
  end


  ##
  ## Page helpers
  ##

  ##
  ## Attachments
  ##

  ##
  ## Misc
  ##

  #
  # Misc
  #

 # Get the specific template name for a given post.
 #
 # @since 3.4.0
 # @since 4.7.0 Now works with any post type, not just pages.
 #
 # @param [int|WP_Post] post Optional. Post ID or WP_Post object. Default is global $post.
 # @return [string|false] Page template filename. Returns an empty string when the default page template
 #  is in use. Returns false if the post does not exist.
def get_page_template_slug( post = nil ) 
  post = get_post( post )

  return false if post.nil?

  template = get_post_meta( post.id, '_wp_page_template', true )

  return '' if !template || 'default' == template 

  template
end

  # Display a list of a post's revisions.
  #
  # Can output either a UL with edit links or a TABLE with diff interface, and
  # restore action links.
  #
  # @param [int|WP_Post] post_id Optional. Post ID or WP_Post object. Default is global $post.
  # @param [string]      type    'all' (default), 'revision' or 'autosave'
  def wp_list_post_revisions(post_id = 0, type = 'all' )
    post = get_post post_id
    return if post.nil?

	# $args array with (parent, format, right, left, type) deprecated since 3.6
	if type.is_a? Hash
		type = type['type'].blank? ? type : type['type']
		# _deprecated_argument( __FUNCTION__, '3.6.0' );
	end

  revisions = wp_get_post_revisions(post.id)
  return if revisions.blank?

	rows = ''
  echo = ''
  revisions.each do |revision|
		next unless current_user_can('read_post', revision.id)

		is_autosave = wp_is_post_autosave(revision)
    next if ( ( 'revision' == type && is_autosave ) || ( 'autosave' == type && ! is_autosave ) )

		rows += "\t<li>" + wp_post_revision_title_expanded( revision ) + "</li>\n"
	end

	echo += "<div class='hide-if-js'><p>" + __( 'JavaScript must be enabled to use this feature.' ) + "</p></div>\n"

	echo += "<ul class='post-revisions hide-if-no-js'>\n"
	echo += rows
	echo += '</ul>'
end
end