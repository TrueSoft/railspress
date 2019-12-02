=begin
 * Nav Menu API: Template functions
 *
 * file wp-includes\nav-menu-template.php
=end
module Railspress::NavMenuTemplateHelper

  # Displays a navigation menu.
  #
  # @since 3.0.0
  # @since 4.7.0 Added the `item_spacing` argument.
  #
  # @staticvar array $menu_id_slugs
  #
  # @param [array] args {
  #     Optional. Array of nav menu arguments.
  #
  #     @type int|string|WP_Term $menu            Desired menu. Accepts a menu ID, slug, name, or object. Default empty.
  #     @type string             $menu_class      CSS class to use for the ul element which forms the menu. Default 'menu'.
  #     @type string             $menu_id         The ID that is applied to the ul element which forms the menu.
  #                                               Default is the menu slug, incremented.
  #     @type string             $container       Whether to wrap the ul, and what to wrap it with. Default 'div'.
  #     @type string             $container_class Class that is applied to the container. Default 'menu-{menu slug}-container'.
  #     @type string             $container_id    The ID that is applied to the container. Default empty.
  #     @type callable|bool      $fallback_cb     If the menu doesn't exists, a callback function will fire.
  #                                               Default is 'wp_page_menu'. Set to false for no fallback.
  #     @type string             $before          Text before the link markup. Default empty.
  #     @type string             $after           Text after the link markup. Default empty.
  #     @type string             $link_before     Text before the link text. Default empty.
  #     @type string             $link_after      Text after the link text. Default empty.
  #     @type bool               $echo            Whether to echo the menu or return it. Default true.
  #     @type int                $depth           How many levels of the hierarchy are to be included. 0 means all. Default 0.
  #     @type object             $walker          Instance of a custom walker class. Default empty.
  #     @type string             $theme_location  Theme location to be used. Must be registered with register_nav_menu()
  #                                               in order to be selectable by the user.
  #     @type string             $items_wrap      How the list items should be wrapped. Default is a ul with an id and class.
  #                                               Uses printf() format with numbered placeholders.
  #     @type string             $item_spacing    Whether to preserve whitespace within the menu's HTML. Accepts 'preserve' or 'discard'. Default 'preserve'.
  # }
  # @return [string|false|void] Menu output if $echo is false, false if there are no items or no menu was found.
  def wp_nav_menu( args = {} )
    # TODO static
    menu_id_slugs = []

    defaults = {
        menu:             '',
        container:        'div',
        container_class:  '',
        container_id:     '',
        menu_class:       'menu',
        menu_id:          '',
        echo:             true,
        fallback_cb:      'wp_page_menu',
        before:           '',
        after:            '',
        link_before:      '',
        link_after:       '',
        items_wrap:       '<ul id="%1$s" class="%2$s">%3$s</ul>',
        item_spacing:     'preserve',
        depth:            0,
        walker:           '',
        theme_location:   '',
    }

    args = Railspress::Functions.wp_parse_args(args, defaults )

    unless ['preserve', 'discard'].include?(args[:item_spacing])
      # invalid value, fall back to default.
      args[:item_spacing] = defaults[:item_spacing]
    end

    # Filters the arguments used to display a navigation menu.
    args = apply_filters('wp_nav_menu_args', args)

    # Filters whether to short-circuit the wp_nav_menu() output.
    #
    # Returning a non-null value to the filter will short-circuit
    # wp_nav_menu(), echoing that value if $args->echo is true,
    # returning that value otherwise.
    #
    # @param string|null $output Nav menu output to short-circuit with. Default null.
    # @param stdClass    $args   An object containing wp_nav_menu() arguments.
    nav_menu = apply_filters('pre_wp_nav_menu', nil, args)

    unless nav_menu.nil?
      if args[:echo]
        echo nav_menu
        return
      end
      return nav_menu
    end

    # Get the nav menu based on the requested menu
    menu = wp_get_nav_menu_object(args[:menu])

    # Get the nav menu based on the theme_location
    if !menu && args[:theme_location]
      locations = get_nav_menu_locations
      if locations && !locations[args[:theme_location]].blank?
        menu = wp_get_nav_menu_object(locations[args[:theme_location]])
      end
    end

    menu_items = nil

    # get the first menu that has items if we still can't find a menu
    if !menu && !args[:theme_location]
      menus = wp_get_nav_menus
      menus.each do |menu_maybe|
        if ( menu_items = wp_get_nav_menu_items( menu_maybe.term_id, {update_post_term_cache: false } ) )
          menu = menu_maybe
          break
        end
      end
    end

    args[:menu] = menu if args[:menu].blank?

    # If the menu exists, get its items.
    if menu && !menu.is_a?(Railspress::WP_Error) && menu_items.blank?
      menu_items = wp_get_nav_menu_items(menu, {update_post_term_cache: false } )
    end

    # If no menu was found:
    #  - Fall back (if one was specified), or bail.
    #
    # If no menu items were found:
    #  - Fall back, but only if no theme location was specified.
    #  - Otherwise, bail.
    if ( ! menu || menu.is_a?(Railspress::WP_Error) || (menu_items.blank? && ! args[:theme_location] ) ) && !args[:fallback_cb].nil? && args[:fallback_cb] && true # is_callable( args[:fallback_cb] )
      # return call_user_func( args[:fallback_cb], args )
      if args[:fallback_cb].include? '.'
        the_class, the_method = args[:fallback_cb].split('.', 2)
        return the_class.constantize.send(the_method, args) # TODO error when fallback: cannot access FormattingHelper
      else
        return send(args[:fallback_cb], args)
      end
    end

    if  ! menu || menu.is_a?( Railspress::WP_Error)
      return false
    end

    nav_menu = items = ''

    show_container = false
    if args[:container]
      # Filters the list of HTML tags that are valid for use as menu containers.
      allowed_tags = apply_filters( 'wp_nav_menu_container_allowedtags', ['div', 'nav'] )
      if args[:container].is_a?(String) && allowed_tags.include?(args[:container])
        show_container = true
        opt_class      = args[:container_class].blank? ? ' class="menu-' + menu.slug + '-container"' : ' class="' + esc_attr( args[:container_class] ) + '"'
        opt_id         = args[:container_id].blank? ? '' : ' id="' + esc_attr( args[:container_id] ) + '"'
        nav_menu      += '<' + args[:container] + opt_id + opt_class + '>'
      end
    end

    # Set up the $menu_item variables
    menu_items = _wp_menu_item_classes_by_context( menu_items.to_a )

    sorted_menu_items = {}
    menu_items_with_children = {}
    menu_items.each do |menu_item|
      sorted_menu_items[menu_item.menu_order] = menu_item
      if !menu_item.menu_item_parent.blank? && menu_item.menu_item_parent != 0
        menu_items_with_children[menu_item.menu_item_parent] = true
      end
    end

    # TODO Add the menu-item-has-children class where applicable
    if menu_items_with_children
      sorted_menu_items.each_value do  |menu_item|
         if  menu_items_with_children[ menu_item.id ]
           menu_item.classes << 'menu-item-has-children'
         end
      end
    end

    menu_items = nil
    menu_item = nil

    # Filters the sorted list of menu item objects before generating the menu's HTML.
    sorted_menu_items = apply_filters('wp_nav_menu_objects', sorted_menu_items.values, args)

    items += walk_nav_menu_tree( sorted_menu_items, args[:depth], args )
    sorted_menu_items = nil

    # Attributes
    if !args[:menu_id].blank?
      wrap_id = args[:menu_id]
    else
      wrap_id = 'menu-' + menu.slug
      # TODO while menu_id_slugs.include?(wrap_id)
      #   if ( preg_match( '#-(\d+)$#', $wrap_id, $matches ) )
      #     wrap_id = preg_replace( '#-(\d+)$#', '-' + ++$matches[1], wrap_id )
      #   else
      #     wrap_id = wrap_id + '-1'
      #   end
      # end
    end
    menu_id_slugs << wrap_id

    wrap_class = args[:menu_class] ? args[:menu_class] : ''

    # Filters the HTML list content for navigation menus.
    items = apply_filters('wp_nav_menu_items', items, args)
    # Filters the HTML list content for a specific navigation menu.
    items = apply_filters("wp_nav_menu_#{menu.slug}_items", items, args)

    # Don't print any markup if there are no items at this point.
    return false if items.blank?

    nav_menu += sprintf( args[:items_wrap], esc_attr(wrap_id ), esc_attr( wrap_class ), items )
    items = nil

    if  show_container
      nav_menu += '</' + args[:container] + '>'
    end

    # Filters the HTML content for navigation menus.
    nav_menu = apply_filters('wp_nav_menu', nav_menu, args).html_safe

    if args[:echo]
      # echo nav_menu
      nav_menu
    else
      return nav_menu
    end
  end

  # Add the class property classes for the current context, if applicable.
  #
  # @global WP_Query   $wp_query
  # @global WP_Rewrite $wp_rewrite
  #
  # @param [array] menu_items The current menu item objects to which to add the class property information.
  def _wp_menu_item_classes_by_context(menu_items)
    # TODO queried_object?
    queried_object    = @wp_query.get_queried_object
    queried_object_id = @wp_query.queried_object_id

    active_object               = ''
    active_ancestor_item_ids    = []
    active_parent_item_ids      = []
    active_parent_object_ids    = []
    possible_taxonomy_ancestors = []
    possible_object_parents     = []
    home_page_id           = get_option( 'page_for_posts' ).to_i

    front_page_url         = main_app.root_url
    front_page_id          = get_option('page_on_front').to_i
    ppp_id = get_option('wp_page_for_privacy_policy' )
    privacy_policy_page_id = (ppp_id.is_a?(String) || ppp_id.is_a?(Integer)) ? ppp_id.to_i : 0

    menu_items.each do |menu_item|
      menu_item.current = false
      classes = menu_item.classes||[]
      classes << 'menu-item'
      classes << 'menu-item-type-' + menu_item.type
      classes << 'menu-item-object-' + menu_item.object

      # This menu item is set as the 'Front Page'.
      if 'post_type' == menu_item.type && front_page_id == menu_item.object_id_.to_i
        classes << 'menu-item-home'
      end

      # This menu item is set as the 'Privacy Policy Page'.
      if 'post_type' == menu_item.type && privacy_policy_page_id == menu_item.object_id_.to_i
        classes << 'menu-item-privacy-policy'
      end

      # if the menu item corresponds to a taxonomy term for the currently-queried non-hierarchical post object
      if @wp_query.is_singular && 'taxonomy' == menu_item.type && possible_object_parents.include?(menu_item.object_id_)
          active_parent_object_ids << menu_item.object_id_.to_i
          active_parent_item_ids << menu_item.db_id.to_i
          # active_object << queried_object.post_type

      # if the menu item corresponds to the currently-queried post or taxonomy object
      elsif  menu_item.object_id_ == queried_object_id &&
          ( ( !home_page_id.blank? && 'post_type' == menu_item.type && @wp_query.is_home && home_page_id == menu_item.object_id_ ) ||
              ( 'post_type' == menu_item.type && @wp_query.is_singular) ||
              ( 'taxonomy' == menu_item.type && ( @wp_query.is_category || @wp_query.is_tag || @wp_query.is_tax ) && queried_object.taxonomy == menu_item.object)
          )
        classes << 'current-menu-item'
        menu_item.current = true
        _anc_id                     = menu_item.db_id.to_i

        # while (
        # ( $_anc_id = get_post_meta( $_anc_id, '_menu_item_menu_item_parent', true ) ) &&
        #     ! in_array( $_anc_id, $active_ancestor_item_ids )
        # ) {
        #     active_ancestor_item_ids << _anc_id
        # }

        if ( 'post_type' == menu_item.type && 'page' == menu_item.object )
            # Back compat classes for pages to match wp_page_menu()
           classes << 'page_item'
           classes << 'page-item-' + menu_item.object_id_
           classes << 'current_page_item'
        end

             active_parent_item_ids << menu_item.menu_item_parent.to_i
             active_parent_object_ids << menu_item.post_parent.to_i
             active_object              = menu_item.object

       # if the menu item corresponds to the currently-queried post type archive
       else
      end
      # TODO ...

      # back-compat with wp_page_menu: add "current_page_parent" to static home page link for any non-page query
      if !home_page_id.blank? && 'post_type' == menu_item.type && # ?wp_query.is_page.blank? &&
            home_page_id == menu_item.object_id_
         classes << 'current_page_parent'
      end

      menu_item.classes = classes.uniq
    end
    active_ancestor_item_ids = active_ancestor_item_ids.uniq.select {|id| !id.blank? && id != 0  }
    active_parent_item_ids   = active_parent_item_ids.uniq.select {|id| !id.blank? && id != 0  }
    active_parent_object_ids = active_parent_object_ids.uniq.select {|id| !id.blank? && id != 0  }

    # set parent's class
    menu_items.each do |parent_item|
      classes = parent_item.classes
      # parent_item.current_item_ancestor = false
      # parent_item.current_item_parent = false


      parent_item.classes = classes.uniq
    end
    menu_items
  end

  # Retrieve the HTML list content for nav menu items.
  #
  # @uses Walker_Nav_Menu to create HTML list content.
  # @since 3.0.0
  #
  # @param [array]    items The menu items, sorted by each menu item's menu order.
  # @param [int]      depth Depth of the item in reference to parents.
  # @param [stdClass] r     An object containing wp_nav_menu() arguments.
  # @return [string] The HTML list content for the menu items.
  def walk_nav_menu_tree( items, depth, r )
    walker =  r[:walker].blank? ? Railspress::WalkerNavMenu.new : r[:walker]
    walker.walk items, depth, r
  end


end