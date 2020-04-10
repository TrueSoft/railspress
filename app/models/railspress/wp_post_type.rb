=begin
 * Post API: WP_Post_Type class
 *
 * file wp-includes\class-wp-post-type.php
=end
module Railspress

  # Core class used for interacting with post types.
  #
  # @see register_post_type()
  class WpPostType

    include Railspress::Functions
    include Railspress::Plugin
    # include Railspress::Load
    # include Railspress::OptionsHelper
    include Railspress::TaxonomyLib

    # Post type key.
    attr_accessor :name

    # Name of the post type shown in the menu. Usually plural.
    attr_accessor :label

    # Labels object for this post type.
    #
    # If not set, post labels are inherited for non-hierarchical types and page labels for hierarchical ones.
    attr_accessor :labels

    #	A short descriptive summary of what the post type is.
    #
    # Default empty.
    attr_accessor :description

    # Whether a post type is intended for use publicly either via the admin interface or by front-end users.
    #
    # While the default settings of $exclude_from_search, $publicly_queryable, $show_ui, and $show_in_nav_menus
    # are inherited from public, each does not rely on this relationship and controls a very specific intention.
    #
    # Default false.
    #
    # @since 4.6.0
    # @var bool $public
    attr_accessor :public

    # Whether the post type is hierarchical (e.g. page).
    #
    # Default false.
    #
    # @since 4.6.0
    # @var bool $hierarchical
    attr_accessor :hierarchical

    # Whether to exclude posts with this post type from front end search
    # results.
    #
    # Default is the opposite value of $public.
    #
    # @since 4.6.0
    # @var bool $exclude_from_search
    attr_accessor :exclude_from_search

    # Whether queries can be performed on the front end for the post type as part of `parse_request()`.
    #
    # Endpoints would include:
    # - `?post_type={post_type_key}`
    # - `?{post_type_key}={single_post_slug}`
    # - `?{post_type_query_var}={single_post_slug}`
    #
    # Default is the value of $public.
    #
    # @since 4.6.0
    # @var bool $publicly_queryable
    attr_accessor :publicly_queryable

    # Whether to generate and allow a UI for managing this post type in the admin.
    #
    # Default is the value of $public.
    #
    # @since 4.6.0
    # @var bool $show_ui
    attr_accessor :show_ui

    # Where to show the post type in the admin menu.
    #
    # To work, $show_ui must be true. If true, the post type is shown in its own top level menu. If false, no menu is
    # shown. If a string of an existing top level menu (eg. 'tools.php' or 'edit.php?post_type=page'), the post type
    # will be placed as a sub-menu of that.
    #
    # Default is the value of $show_ui.
    #
    # @since 4.6.0
    # @var bool $show_in_menu
    attr_accessor :show_in_menu

    # Makes this post type available for selection in navigation menus.
    #
    # Default is the value $public.
    #
    # @since 4.6.0
    # @var bool $show_in_nav_menus
    attr_accessor :show_in_nav_menus

    # Makes this post type available via the admin bar.
    #
    # Default is the value of $show_in_menu.
    #
    # @since 4.6.0
    # @var bool $show_in_admin_bar
    attr_accessor :show_in_admin_bar

    # The position in the menu order the post type should appear.
    #
    # To work, $show_in_menu must be true. Default null (at the bottom).
    #
    # @since 4.6.0
    # @var int $menu_position
    attr_accessor :menu_position

    # The URL to the icon to be used for this menu.
    #
    # Pass a base64-encoded SVG using a data URI, which will be colored to match the color scheme.
    # This should begin with 'data:image/svg+xml;base64,'. Pass the name of a Dashicons helper class
    # to use a font icon, e.g. 'dashicons-chart-pie'. Pass 'none' to leave div.wp-menu-image empty
    # so an icon can be added via CSS.
    #
    # Defaults to use the posts icon.
    #
    # @since 4.6.0
    # @var string $menu_icon
    attr_accessor :menu_icon

    # The string to use to build the read, edit, and delete capabilities.
    #
    # May be passed as an array to allow for alternative plurals when using
    # this argument as a base to construct the capabilities, e.g.
    # array( 'story', 'stories' ). Default 'post'.
    #
    # @since 4.6.0
    # @var string $capability_type
    attr_accessor :capability_type

    # Whether to use the internal default meta capability handling.
    #
    # Default false.
    #
    # @since 4.6.0
    # @var bool $map_meta_cap
    attr_accessor :map_meta_cap

    # Provide a callback function that sets up the meta boxes for the edit form.
    #
    # Do `remove_meta_box()` and `add_meta_box()` calls in the callback. Default null.
    #
    # @since 4.6.0
    # @var string $register_meta_box_cb
    attr_accessor :register_meta_box_cb

    # An array of taxonomy identifiers that will be registered for the post type.
    #
    # Taxonomies can be registered later with `register_taxonomy()` or `register_taxonomy_for_object_type()`.
    #
    # Default empty array.
    #
    # @since 4.6.0
    # @var array $taxonomies
    attr_accessor :taxonomies

    # Whether there should be post type archives, or if a string, the archive slug to use.
    #
    # Will generate the proper rewrite rules if $rewrite is enabled. Default false.
    #
    # @since 4.6.0
    # @var bool|string $has_archive
    attr_accessor :has_archive

    # Sets the query_var key for this post type.
    #
    # Defaults to $post_type key. If false, a post type cannot be loaded at `?{query_var}={post_slug}`.
    # If specified as a string, the query `?{query_var_string}={post_slug}` will be valid.
    #
    # @since 4.6.0
    # @var string|bool $query_var
    attr_accessor :query_var

    # Whether to allow this post type to be exported.
    #
    # Default true.
    #
    # @since 4.6.0
    # @var bool $can_export
    attr_accessor :can_export

    # Whether to delete posts of this type when deleting a user.
    #
    # If true, posts of this type belonging to the user will be moved to trash when then user is deleted.
    # If false, posts of this type belonging to the user will *not* be trashed or deleted.
    # If not set (the default), posts are trashed if post_type_supports( 'author' ).
    # Otherwise posts are not trashed or deleted. Default null.
    #
    # @since 4.6.0
    # @var bool $delete_with_user
    attr_accessor :delete_with_user

    # Whether this post type is a native or "built-in" post_type.
    #
    # Default false.
    #
    # @since 4.6.0
    # @var bool $_builtin
    attr_accessor :_builtin

    # URL segment to use for edit link of this post type.
    #
    # Default 'post.php?post=%d'.
    #
    # @since 4.6.0
    # @var string $_edit_link
    attr_accessor :_edit_link

    # Post type capabilities.
    #
    # @since 4.6.0
    # @var object $cap
    attr_accessor :cap

    # Triggers the handling of rewrites for this post type.
    #
    # Defaults to true, using $post_type as slug.
    #
    # @since 4.6.0
    # @var array|false $rewrite
    attr_accessor :rewrite

    # The features supported by the post type.
    #
    # @since 4.6.0
    # @var array|bool $supports
    attr_accessor :supports

    # Whether this post type should appear in the REST API.
    #
    # Default false. If true, standard endpoints will be registered with
    # respect to $rest_base and $rest_controller_class.
    #
    # @since 4.7.4
    # @var bool $show_in_rest
    attr_accessor :show_in_rest

    # The base path for this post type's REST API endpoints.
    #
    # @since 4.7.4
    # @var string|bool $rest_base
    attr_accessor :rest_base

    # The controller for this post type's REST API endpoints.
    #
    # Custom controllers must extend WP_REST_Controller.
    #
    # @since 4.7.4
    # @var string|bool $rest_controller_class
    attr_accessor :rest_controller_class

    # Constructor.
    #
    # Will populate object properties from the provided arguments and assign other
    # default properties based on that information.
    #
    # @see register_post_type()
    #
    # @param [string]       post_type Post type key.
    # @param [array|string] args      Optional. Array or string of arguments for registering a post type.
    #                                 Default empty array.
    def initialize(post_type, args = {})
      @description = ''
      @public = false
      @hierarchical = false
      @capability_type = 'post'
      @map_meta_cap = false
      @taxonomies = {}
      @has_archive = false
      @can_export = true
      @_builtin = false
      @_edit_link = 'post.php?post=%d'
      @name = post_type
      set_props args
    end

    # Sets post type properties.
    #
    # @param [array|string] args Array or string of arguments for registering a post type.
    def set_props(args)
      args = Functions.wp_parse_args args

      # Filters the arguments for registering a post type.
      args = apply_filters('register_post_type_args', args, @name)

      has_edit_link = !args['_edit_link'].blank?

      # Args prefixed with an underscore are reserved for internal use.
      defaults = {
          'labels' => {},
          'description' => '',
          'public' => false,
          'hierarchical' => false,
          'exclude_from_search' => nil,
          'publicly_queryable' => nil,
          'show_ui' => nil,
          'show_in_menu' => nil,
          'show_in_nav_menus' => nil,
          'show_in_admin_bar' => nil,
          'menu_position' => nil,
          'menu_icon' => nil,
          'capability_type' => 'post',
          'capabilities' => {},
          'map_meta_cap' => nil,
          'supports' => [],
          'register_meta_box_cb' => nil,
          'taxonomies' => [],
          'has_archive' => false,
          'rewrite' => true,
          'query_var' => true,
          'can_export' => true,
          'delete_with_user' => nil,
          'show_in_rest' => false,
          'rest_base' => false,
          'rest_controller_class' => false,
          '_builtin' => false,
          '_edit_link' => 'post.php?post=%d',
      }

      args = defaults.merge args

      args['name'] = @name

      # If not set, default to the setting for public.
      args['publicly_queryable'] = args['public'] if args['publicly_queryable'].nil?

      # If not set, default to the setting for public.
      args['show_ui'] = args['public'] if args['show_ui'].nil?

      # If not set, default to the setting for show_ui.
      if (args['show_in_menu'].nil? || !args['show_ui'])
        args['show_in_menu'] = args['show_ui']
      end

      # If not set, default to the whether the full UI is shown.
      args['show_in_admin_bar'] = args['show_in_menu'] if args['show_in_admin_bar'].nil?

      # If not set, default to the setting for public.
      args['show_in_nav_menus'] = args['public'] if args['show_in_nav_menus'].nil?

      # If not set, default to true if not public, false if public.
      args['exclude_from_search'] = !args['public'] if args['exclude_from_search'].nil?

      # Back compat with quirky handling in version 3.0. #14122.
      if args['capabilities'].blank? && args['map_meta_cap'].nil? && ['post', 'page'].include?(args['capability_type'])
        args['map_meta_cap'] = true
      end

      # If not set, default to false.
      args['map_meta_cap'] = false if args['map_meta_cap'].nil?

      # If there's no specified edit link and no UI, remove the edit link.
      if !args['show_ui'] && !has_edit_link
        args['_edit_link'] = ''
      end

      @cap = Railspress::PostsHelper.get_post_type_capabilities(args)
      args.delete 'capabilities'

      if args['capability_type'].is_a? Array
        args['capability_type'] = args['capability_type'][0]
      end

      if args['query_var']
        if true == args['query_var']
          args['query_var'] = @name
        else
          args['query_var'] = sanitize_title_with_dashes(args['query_var'])
        end
      end

      # TODO continue
      # if ( false != $args['rewrite'] && ( is_admin() || !get_option( 'permalink_structure' ).blank? ) )
      #         args['rewrite'] ||= {}
      #         args['rewrite']['slug'] = @name if args['rewrite']['slug'].blank?
      #         args['rewrite']['with_front'] = true if args['rewrite']['with_front'].blank?
      #         args['rewrite']['pages'] = true if args['rewrite']['pages'] .blank?
      #
      #         if ( ! isset( $args['rewrite']['feeds'] ) || ! $args['has_archive'] ) {
      #             $args['rewrite']['feeds'] = (bool) $args['has_archive'];
      #         }
      #         if ( ! isset( $args['rewrite']['ep_mask'] ) ) {
      #             if ( isset( $args['permalink_epmask'] ) ) {
      #                 $args['rewrite']['ep_mask'] = $args['permalink_epmask'];
      #             } else {
      #                 $args['rewrite']['ep_mask'] = EP_PERMALINK;
      #             }
      #        }
      # end

      args.each_pair do |property_name, property_value|
        self.send(property_name + '=', property_value)
      end

      @labels = Railspress::PostsHelper.get_post_type_labels(self)
      @label = @labels['name']
    end

    # Sets the features support for the post type.
    def add_supports
      if !self.supports.empty?
        Railspress::PostsHelper.add_post_type_support(self.name, self.supports)
          self.supports = nil
      elsif false != self.supports
        # Add default features.
        Railspress::PostsHelper.add_post_type_support(self.name, [ 'title', 'editor' ])
      end
    end

    # Adds the necessary rewrite rules for the post type.
    def add_rewrite_rules
      # global $wp_rewrite, $wp;

      # if ( false != @query_var && $wp && is_post_type_viewable( self ) )
      #   $wp->add_query_var( @query_var )
      # end

      if ( false != @rewrite && ( is_admin() || !get_option( 'permalink_structure' ).blank? ) )
        if @hierarchical
          add_rewrite_tag( "%#{@name}%", '(.+?)', @query_var ? "#{@query_var}=" : "post_type=#{@name}&pagename=" )
        else
          add_rewrite_tag( "%#{@name}%", '([^/]+)', @query_var ? "#{@query_var}=" : "post_type=#{@name}&name=" )
        end

        if @has_archive
          archive_slug = true == @has_archive ? @rewrite['slug'] : @has_archive
          if @rewrite['with_front']
            archive_slug = Railspress.GLOBAL.wp_rewrite.front[1..-1] + archive_slug
          else
            archive_slug = @root + archive_slug;
          end

          # TODO continue
          # add_rewrite_rule( "#{archive_slug}/?$", "index.php?post_type=#{@name}", 'top' )
          # if ( @rewrite['feeds'] && Railspress.GLOBAL.wp_rewrite.feeds )
          #   feeds = '(' + Railspress.GLOBAL.wp_rewrite.feeds.join('|').strip   + ')'
          #   add_rewrite_rule( "#{archive_slug}/feed/#{feeds}/?$", "index.php?post_type=#{@name}" + '&feed=$matches[1]', 'top' )
          #   add_rewrite_rule( "#{archive_slug}/#{feeds}/?$", "index.php?post_type=#{@name}" + '&feed=$matches[1]', 'top' )
          # end
          # if @rewrite['pages']
          #   add_rewrite_rule( "{$archive_slug}/{$wp_rewrite->pagination_base}/([0-9]{1,})/?$", "index.php?post_type=$this->name" + '&paged=$matches[1]', 'top' )
          # end
        end

        permastruct_args         = @rewrite
        permastruct_args['feed'] = permastruct_args['feeds']
        Railspress.GLOBAL.wp_rewrite.add_permastruct( @name, "#{@rewrite['slug']}/%#{@name}%", permastruct_args )
      end
    end

    # Registers the post type meta box if a custom callback was specified.
    def register_meta_boxes
      if self.register_meta_box_cb
        add_action( 'add_meta_boxes_' + self.name, self.register_meta_box_cb, 10, 1)
      end
    end

    # Adds the future post hook action for the post type.
    def add_hooks
      add_action( 'future_' + self.name, '_future_post_hook', 5, 2 )
    end

    # Registers the taxonomies for the post type.
    def register_taxonomies
      @taxonomies.each do |taxonomy|
        register_taxonomy_for_object_type(taxonomy, self.name)
      end
    end

    # Removes the features support for the post type.
    def remove_supports
      Railspress.GLOBAL._wp_post_type_features.delete self.name
    end

    # Removes any rewrite rules, permastructs, and rules for the post type.
    def remove_rewrite_rules
      # TODO implement class-wp-post-type.php remove_rewrite_rules()
    end

    # Unregisters the post type meta box if a custom callback was specified.
    def unregister_meta_boxes
      if self.register_meta_box_cb
        remove_action('add_meta_boxes_' + self.name, self.register_meta_box_cb, 10)
      end
    end

    # Removes the post type from all taxonomies.
    def unregister_taxonomies()
      get_object_taxonomies(self.name).each do |taxonomy|
        unregister_taxonomy_for_object_type(taxonomy, self.name)
      end
    end

    # Removes the future post hook action for the post type.
    def remove_hooks
      remove_action( 'future_' + self.name, '_future_post_hook', 5 )
    end
  end
end