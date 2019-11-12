=begin
 * Navigation Menu functions
 *
 * file wp-includes\nav-menu.php
=end
module Railspress::NavMenuHelper

  # Returns a navigation menu object.
  #
  # @param [int|string|WP_Term] menu Menu ID, slug, name, or object.
  # @return [WP_Term|false] False if $menu param isn't supplied or term does not exist, menu object if successful.
  def wp_get_nav_menu_object( menu )
    menu_obj = false
    menu_obj = menu if menu.is_a? Railspress::NavMenu

    if menu.is_a? String
      menu_obj = Railspress::NavMenu.joins(:term).where(Railspress::Term.table_name => {'slug': menu}).first
    end
    if menu.is_a? Integer
      menu_obj = Railspress::NavMenu.where(term_id: menu).first
    end

    # TODO if menu && !menu_obj
    #   menu_obj = get_term(menu, 'nav_menu')
    #   menu_obj = get_term_by('slug', menu, 'nav_menu') unless menu_obj
    #   menu_obj = get_term_by('name', menu, 'nav_menu') unless menu_obj
    # end

    if !menu_obj || menu_obj.is_a?(Railspress::WP_Error)
      menu_obj = false
    end

    # Filters the nav_menu term retrieved for wp_get_nav_menu_object().
    apply_filters('wp_get_nav_menu_object', menu_obj, menu)
  end

  # Retrieves all registered navigation menu locations in a theme.
  #
  # @return array Registered navigation menu locations. If none are registered, an empty array.
  def get_registered_nav_menus # TODO implement register_nav_menus for main_app
    # global $_wp_registered_nav_menus
    # if ( isset( $_wp_registered_nav_menus ) ) {
    #     return $_wp_registered_nav_menus;
    # }
    []
    end

  # Retrieves all registered navigation menu locations and the menus assigned to them.
  #
  # @return [array] Registered navigation menu locations and the menus assigned them.
  #                 If none are registered, an empty array.
  def get_nav_menu_locations
    locations = get_theme_mod('nav_menu_locations')
    locations.is_a?(Hash) ? locations : {}
  end

  # Determines whether a registered nav menu location has a menu assigned to it.
  #
  # @param [string] location Menu location identifier.
  # @return [bool] Whether location has a menu.
  def has_nav_menu(location)
    has_nav_menu = false

    registered_nav_menus = get_registered_nav_menus
    unless registered_nav_menus[location].blank?
      locations    = get_nav_menu_locations
      has_nav_menu = !locations[location].blank?
    end

    # Filters whether a nav menu is assigned to the specified location.
    apply_filters('has_nav_menu', has_nav_menu, location)
  end

  # Creates a navigation menu.
  #
  # Note that `$menu_name` is expected to be pre-slashed.
  #
  # @param [string] menu_name Menu name.
  # @return [int|WP_Error] Menu ID on success, WP_Error object on failure.
  def wp_create_nav_menu(menu_name)
    # expected_slashed ($menu_name)
    wp_update_nav_menu_object(0, {'menu-name':  menu_name })
  end

  # Save the properties of a menu or create a new menu with those properties.
  #
  # Note that `$menu_data` is expected to be pre-slashed.
  #
  # @param [int]   menu_id   The ID of the menu or "0" to create a new menu.
  # @param [array] menu_data The array of menu data.
  # @return int|WP_Error Menu ID on success, WP_Error object on failure.
  def wp_update_nav_menu_object(menu_id = 0, menu_data = {} )
    # expected_slashed ($menu_data)
    menu_id = menu_id.to_i

    _menu = wp_get_nav_menu_object( menu_id )

    args = {
        description: menu_data[:description] || '' ,
        name:        menu_data['menu-name'.to_sym] || '' ,
        parent:      menu_data[:parent] || 0 ,
        slug:        nil,
    }
    # double-check that we're not going to have one menu take the name of another
    _possible_existing = get_term_by( 'name', menu_data['menu-name'.to_sym], 'nav_menu' )

    # TODO continue

    return 0 if true # TODO  ! _menu ||  _menu.term_id.blank?

    menu_id = _menu.term_id.to_i

    # TODO
    # update_response = wp_update_term(menu_id, 'nav_menu', args)
    #
    # return update_response if update_response.is_a? Railspress::WP_Error
    #
    # menu_id = update_response['term_id'].to_i

    # Fires after a navigation menu has been successfully updated.
    do_action( 'wp_update_nav_menu', menu_id, menu_data )
    menu_id
  end

  # Returns all navigation menu objects.
  #
  # @param [array] args Optional. Array of arguments passed on to get_terms().
  #                     Default empty array.
  # @return array Menu objects.
  def wp_get_nav_menus(args = {})
    defaults = {
        hide_empty: false,
        orderby: 'name',
    }
    args = wp_parse_args(args, defaults)
    args[:taxonomy] = 'nav_menu'

    # Filters the navigation menu objects being returned.
    apply_filters('wp_get_nav_menus', get_terms(args), args)
  end

  # Return if a menu item is valid.
  #
  # @link https://core.trac.wordpress.org/ticket/13958
  #
  # @since 3.2.0
  # @access private
  #
  # @param [object] item The menu item to check.
  # @return [bool] False if invalid, otherwise true.
  def _is_valid_nav_menu_item(item)
    item._invalid.blank?
  end

  # Retrieves all menu items of a navigation menu.
  #
  # Note: Most arguments passed to the `$args` parameter – save for 'output_key' – are
  # specifically for retrieving nav_menu_item posts from get_posts() and may only
  # indirectly affect the ultimate ordering and content of the resulting nav menu
  # items that get returned from this function.
  #
  # @staticvar array $fetched
  #
  # @param [int|string|WP_Term] menu Menu ID, slug, name, or object.
  # @param [array]               args {
  #     Optional. Arguments to pass to get_posts().
  #
  #     @type string $order       How to order nav menu items as queried with get_posts(). Will be ignored
  #                               if 'output' is ARRAY_A. Default 'ASC'.
  #     @type string $orderby     Field to order menu items by as retrieved from get_posts(). Supply an orderby
  #                               field via 'output_key' to affect the output order of nav menu items.
  #                               Default 'menu_order'.
  #     @type string $post_type   Menu items post type. Default 'nav_menu_item'.
  #     @type string $post_status Menu items post status. Default 'publish'.
  #     @type string $output      How to order outputted menu items. Default ARRAY_A.
  #     @type string $output_key  Key to use for ordering the actual menu items that get returned. Note that
  #                               that is not a get_posts() argument and will only affect output of menu items
  #                               processed in this function. Default 'menu_order'.
  #     @type bool   $nopaging    Whether to retrieve all menu items (true) or paginate (false). Default true.
  # }
  # @return [false|array] items Array of menu items, otherwise false.
  def wp_get_nav_menu_items(menu, args = {})
    if menu.is_a? Railspress::NavMenu
      items = menu.menuitems.to_a
      items.map! {|menu_item| wp_setup_nav_menu_item(menu_item)}
      return items
    end
    menu = wp_get_nav_menu_object( menu )

    return false if menu.nil?

    # static $fetched = array();

    items = get_objects_in_term( menu.term_id, 'nav_menu' )

    return false if  items.is_a? Railspress::WP_Error

    defaults        = {
        order:       'ASC',
        orderby:     'menu_order',
        post_type:   'nav_menu_item',
        post_status: 'publish',
        output:      :ARRAY_A,
        output_key:  'menu_order',
        nopaging:    true,
    }
    args           = wp_parse_args(args, defaults )
    args[:include] = items

    if !items.empty?
      items = get_posts( args )
    else
      items = []
    end

    # Get all posts and terms at once to prime the caches
    if empty( fetched[ menu.term_id ] ) && ! wp_using_ext_object_cache()
      fetched[ menu.term_id ] = true
      posts                     = {}
      terms                     = {}
      items.each do |item|
        object_id = item.object_id_ # get_post_meta( item.id, '_menu_item_object_id', true )
        object    = item.object # get_post_meta( item.id, '_menu_item_object', true )
        type      = item.type # get_post_meta( item.id, '_menu_item_type', true )

        if 'post_type' == type
          posts[ object ][] = object_id
        elsif 'taxonomy' == type
          terms[ object ][] = object_id
        end
      end

      unless posts.blank?
        posts.each_pair do |post_type, post_type_value|
          get_posts({
                        post__in:               post_type_value,
                        post_type:              post_type,
                        nopaging:               true,
                        update_post_term_cache: false,
                    }
          )
        end
      end
      posts = nil

      unless terms.blank?
        terms.each_pair do |taxonomy, taxonomy_value|
          get_terms({
                        taxonomy: taxonomy,
                        include:      taxonomy_value,
                        hierarchical: false,
                    }
          )
        end
      end
      terms = nil
    end

    items.map! {|menu_item| wp_setup_nav_menu_item(menu_item)}

    if !is_admin()  # Remove invalid items only in front end
      items = array_filter( items, '_is_valid_nav_menu_item' )
    end

    if ( :ARRAY_A == args['output'] )
      items = wp_list_sort(
          items, {args['output_key'] => 'ASC' }
      );
      $i     = 1;
      # TODO foreach ( $items as $k => $item ) {
      #   $items[ $k ].{$args['output_key']} = $i++
      # }
    end

    # Filters the navigation menu items being returned.
    apply_filters( 'wp_get_nav_menu_items', items, menu, args )
  end

  # Decorates a menu item object with the shared navigation menu item properties.
  #
  # Properties:
  # - ID:               The term_id if the menu item represents a taxonomy term.
  # - attr_title:       The title attribute of the link element for this menu item.
  # - classes:          The array of class attribute values for the link element of this menu item.
  # - db_id:            The DB ID of this item as a nav_menu_item object, if it exists (0 if it doesn't exist).
  # - description:      The description of this menu item.
  # - menu_item_parent: The DB ID of the nav_menu_item that is this item's menu parent, if any. 0 otherwise.
  # - object:           The type of object originally represented, such as "category," "post", or "attachment."
  # - object_id:        The DB ID of the original object this menu item represents, e.g. ID for posts and term_id for categories.
  # - post_parent:      The DB ID of the original object's parent object, if any (0 otherwise).
  # - post_title:       A "no title" label if menu item represents a post that lacks a title.
  # - target:           The target attribute of the link element for this menu item.
  # - title:            The title of this menu item.
  # - type:             The family of objects originally represented, such as "post_type" or "taxonomy."
  # - type_label:       The singular label used to describe this type of menu item.
  # - url:              The URL to which this menu item points.
  # - xfn:              The XFN relationship expressed in the link of this menu item.
  # - _invalid:         Whether the menu item represents an object that no longer exists.
  #
  # @param [object] menu_item The menu item to modify.
  # @return [object] menu_item The menu item with standard menu item properties.
  def wp_setup_nav_menu_item( menu_item )
    if !menu_item.post_type.blank?
      if 'nav_menu_item' == menu_item.post_type
        menu_item.db_id            = menu_item.id.to_i
        menu_item.menu_item_parent = menu_item.menu_item_parent.blank? ? get_post_meta( menu_item.id, '_menu_item_menu_item_parent', true ) : menu_item.menu_item_parent
        menu_item.object_id_       = menu_item.object_id_.blank? ? get_post_meta( menu_item.id, '_menu_item_object_id', true ) : menu_item.object_id_
        menu_item.object           = menu_item.object.blank? ? get_post_meta( menu_item.id, '_menu_item_object', true ) : menu_item.object
        menu_item.type             = menu_item.type.blank? ? get_post_meta( menu_item.id, '_menu_item_type', true ) : menu_item.type

        if 'post_type' == menu_item.type
          object = get_post_type_object(menu_item.object)
          if object
            menu_item.type_label = object.labels.singular_name
          else
            menu_item.type_label = menu_item.object
            menu_item._invalid   = true
          end

          menu_item._invalid = true  if 'trash' == get_post_status( menu_item.object_id_ )

          menu_item.url = get_permalink( menu_item.object_id_ )

          original_object = get_post( menu_item.object_id_ )
          # This filter is documented in wp-includes/post-template.php
          original_title = apply_filters( 'the_title', original_object.post_title, original_object.id )

          if original_title.blank?
            # translators: %d: ID of a post
            original_title = sprintf( t( '#%d (no title)' ), original_object.id )
          end

          menu_item.title = '' == menu_item.post_title ? original_title : menu_item.post_title

        elsif 'post_type_archive' == menu_item.type
          object = get_post_type_object( menu_item.object )
          if object
            menu_item.title      = '' == menu_item.post_title ? object.labels.archives : menu_item.post_title
            post_type_description = object.description
          else
            menu_item._invalid   = true
            post_type_description = ''
          end

          menu_item.type_label = __( 'Post Type Archive' )
          post_content          = wp_trim_words( menu_item.post_content, 200 )
          post_type_description = post_content.blank? ? post_type_description : post_content
          menu_item.url        = get_post_type_archive_link( menu_item.object )
        elsif 'taxonomy' == menu_item.type
          object = get_taxonomy( menu_item.object )
          if object
            menu_item.type_label = object.labels.singular_name
          else
            menu_item.type_label = menu_item.object
            menu_item._invalid   = true
          end

          term_url       = get_term_link( menu_item.object_id.to_i, menu_item.object )
          menu_item.url = term_url.is_a?(Railspress::WP_Error) ? '' : term_url

          original_title = get_term_field( 'name', menu_item.object_id, menu_item.object, 'raw' )

          original_title = # TODO ?? false
          is_wp_error( original_title )

          menu_item.title = '' == menu_item.post_title ? $original_title : menu_item.post_title

        else
          menu_item.type_label = t( 'Custom Link' ) # TODO
          menu_item.title      = menu_item.post_title
          menu_item.url        = menu_item.url.blank? ? get_post_meta( menu_item.ID, '_menu_item_url', true ) : menu_item.url
          if params[:language] && params[:language] != I18n.default_locale.to_s && !menu_item.url.include?('?')
            menu_item.url = menu_item.url + '?' + {language: params[:language]}.to_query
          end
        end

        menu_item.target = menu_item.target.blank? ? get_post_meta( menu_item.ID, '_menu_item_target', true ) : menu_item.target

        # Filters a navigation menu item's title attribute.
# TODO        menu_item.attr_title = menu_item.attr_title.blank? ? apply_filters( 'nav_menu_attr_title', menu_item.post_excerpt ) : menu_item.attr_title

        if menu_item.description.blank?
          # Filters a navigation menu item's description.
          menu_item.description = apply_filters( 'nav_menu_description', wp_trim_words( menu_item.post_content, 200 ) );
        end

        menu_item.classes = menu_item.classes.blank? ? get_post_meta( menu_item.id, '_menu_item_classes', true ) : menu_item.classes
        menu_item.xfn     = menu_item.xfn.blank? ? get_post_meta( menu_item.id, '_menu_item_xfn', true ) : menu_item.xfn
      else
        menu_item.db_id            = 0
        menu_item.menu_item_parent = 0
        menu_item.object_id        = menu_item.id.to_i
        menu_item.type             = 'post_type'

        object                = get_post_type_object( menu_item.post_type )
        menu_item.object     = object.name
        menu_item.type_label = object.labels.singular_name

        if menu_item.post_title.blank?
          # translators: %d: ID of a post
          menu_item.post_title = sprintf( t( '#%d (no title)' ), menu_item.id )
        end

        menu_item.title  = menu_item.post_title
        menu_item.url    = get_permalink( menu_item.ID )
        menu_item.target = ''

        # This filter is documented in wp-includes/nav-menu.php
        menu_item.attr_title = apply_filters( 'nav_menu_attr_title', '' )

        # This filter is documented in wp-includes/nav-menu.php
        menu_item.description = apply_filters( 'nav_menu_description', '' )
        menu_item.classes     = []
        menu_item.xfn         = ''
      end
    elsif !menu_item.taxonomy.blank?
      menu_item.ID               = menu_item.term_id
      menu_item.db_id            = 0
      menu_item.menu_item_parent = 0
      menu_item.object_id        = menu_item.term_id.to_i
      menu_item.post_parent      = menu_item.parent.to_i
      menu_item.type             = 'taxonomy'

      object                = get_taxonomy( menu_item.taxonomy )
      menu_item.object     = object.name
      menu_item.type_label = object.labels.singular_name

      menu_item.title       = menu_item.name
      menu_item.url         = get_term_link( menu_item, menu_item.taxonomy )
      menu_item.target      = ''
      menu_item.attr_title  = ''
      menu_item.description = get_term_field( 'description', menu_item.term_id, menu_item.taxonomy )
      menu_item.classes     = []
      menu_item.xfn         = ''
    end

    # Filters a navigation menu item object.
    apply_filters( 'wp_setup_nav_menu_item', menu_item )
  end

end