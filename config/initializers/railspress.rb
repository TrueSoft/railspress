module Railspress

  ::GLOBAL = GlobalVars.new

  # TODO mailserver_*
  ::READONLY_OPTIONS = %w(siteurl home blogname blogdescription admin_email
    new_admin_email sidebars_widgets category_base tag_base page_for_posts page_on_front template stylesheet
    gmt_offset permalink_structure widget_recent-posts WPLANG show_on_front)
  ::EDITABLE_OPTIONS = []

  # Creates the initial post types when 'init' action is fired.
  def self.create_initial_post_types
    register_post_type('post',
                       {
                           'labels' => {
                               'name_admin_bar' => "Post" # TODO _x('Post', 'add new from admin bar'),
                           },
                           'public' => true,
                           '_builtin' => true, # internal use only. don't use this when registering your own post type.
                           '_edit_link' => 'post.php?post=%d', # internal use only. don't use this when registering your own post type.
                           'capability_type' => 'post',
                           'map_meta_cap' => true,
                           'menu_position' => 5,
                           'hierarchical' => false,
                           'rewrite' => false,
                           'query_var' => false,
                           'delete_with_user' => true,
                           'supports' => ['title', 'editor', 'author', 'thumbnail', 'excerpt', 'trackbacks', 'custom-fields', 'comments', 'revisions', 'post-formats'],
                           'show_in_rest' => true,
                           'rest_base' => 'posts',
                           'rest_controller_class' => 'WP_REST_Posts_Controller',
                       }
    )
    register_post_type('page',
                       {
                           'labels' => {
                               'name_admin_bar' => "Page" # TODO _x( 'Page', 'add new from admin bar' ),
                           },
                           'public' => true,
                           'publicly_queryable' => false,
                           '_builtin' => true, # internal use only. don't use this when registering your own post type.
                           '_edit_link' => 'post.php?post=%d', # internal use only. don't use this when registering your own post type.
                           'capability_type' => 'page',
                           'map_meta_cap' => true,
                           'menu_position' => 20,
                           'hierarchical' => true,
                           'rewrite' => false,
                           'query_var' => false,
                           'delete_with_user' => true,
                           'supports' => ['title', 'editor', 'author', 'thumbnail', 'page-attributes', 'custom-fields', 'comments', 'revisions'],
                           'show_in_rest' => true,
                           'rest_base' => 'pages',
                           'rest_controller_class' => 'WP_REST_Posts_Controller',
                       }
    )

    register_post_type('attachment',
                       {
                           'labels' => {
                               'name' => "Media",
                               'name_admin_bar' => "Media",
                               'add_new' => "Add New",
                               'edit_item' => "Edit Media",
                               'view_item' => "View Attachment Page",
                               'attributes' => "Attachment Attributes"
                           },
                           'public' => true,
                           'show_ui' => true,
                           '_builtin' => true, # internal use only. don't use this when registering your own post type.
                           '_edit_link' => 'post.php?post=%d', # internal use only. don't use this when registering your own post type.
                           'capability_type' => 'post',
                           'capabilities' => {'create_posts' => 'upload_files'},
                           'map_meta_cap' => true,
                           'hierarchical' => false,
                           'rewrite' => false,
                           'query_var' => false,
                           'show_in_nav_menus' => false,
                           'delete_with_user' => true,
                           'supports' => ['title', 'author', 'comments'],
                           'show_in_rest' => true,
                           'rest_base' => 'media',
                           'rest_controller_class' => 'WP_REST_Attachments_Controller',
                       }
    )
    add_post_type_support( 'attachment:audio', 'thumbnail' )
    add_post_type_support( 'attachment:video', 'thumbnail' )

    register_post_type('revision',
                       {
                           'labels' => {
                               'name' => "Revisions",
                               'singular_name' => "Revision",
                           },
                           'public' => false,
                           '_builtin' => true, # internal use only. don't use this when registering your own post type.
                           '_edit_link' => 'revision.php?revision=%d', # internal use only. don't use this when registering your own post type.
                           'capability_type' => 'post',
                           'map_meta_cap' => true,
                           'hierarchical' => false,
                           'rewrite' => false,
                           'query_var' => false,
                           'can_export' => false,
                           'delete_with_user' => true,
                           'supports' => ['author'],
                       }
    )

    register_post_type('nav_menu_item',
                       {
                           'labels' => {
                               'name' => "Navigation Menu Items",
                               'singular_name' => "Navigation Menu Item",
                           },
                           'public' => false,
                           '_builtin' => true, # internal use only. don't use this when registering your own post type.
                           'hierarchical' => false,
                           'rewrite' => false,
                           'delete_with_user' => false,
                           'query_var' => false,
                       }
    )
    # TODO continue
  end

  # Sanitizes a string key.
  #
  # Keys are used as internal identifiers. Lowercase alphanumeric characters, dashes and underscores are allowed.
  #
  # @param [string] key String key
  # @return [string] Sanitized key
  def self.sanitize_key(key)
    raw_key = key
    key.downcase!
    key.gsub! /[^a-z0-9_\-]/, ''

    # Filters a sanitized key string.
    # TODO not working apply_filters('sanitize_key', key, raw_key)
    key
  end

  # Registers a post type.
  #
  # @return WP_Post_Type|WP_Error The registered post type object, or an error object.
  def self.register_post_type(post_type, args = {} )
    GLOBAL.wp_post_types ||= {}

    # Sanitize post type name
    post_type = sanitize_key(post_type)

    if  post_type.blank?  || post_type.length > 20
      # _doing_it_wrong( __FUNCTION__, __( 'Post type names must be between 1 and 20 characters in length.' ), '4.2.0' );
      return WP_Error.new('post_type_length_invalid', ( 'Post type names must be between 1 and 20 characters in length.' ) )
    end

    post_type_object = Railspress::WpPostType.new(post_type, args)
    post_type_object.add_supports()
    post_type_object.add_rewrite_rules()
    post_type_object.register_meta_boxes()

    GLOBAL.wp_post_types[post_type] = post_type_object

    post_type_object.add_hooks()
    post_type_object.register_taxonomies()

    # Fires after a post type is registered.
    # TODO do_action( 'registered_post_type', post_type, post_type_object)

    post_type_object
  end

  # Register support of certain features for a post type.
  #
  # All core features are directly associated with a functional area of the edit
  # screen, such as the editor or a meta box. Features include: 'title', 'editor',
  # 'comments', 'revisions', 'trackbacks', 'author', 'excerpt', 'page-attributes',
  # 'thumbnail', 'custom-fields', and 'post-formats'.
  #
  # Additionally, the 'revisions' feature dictates whether the post type will
  # store revisions, and the 'comments' feature dictates whether the comments
  # count will show on the edit screen.
  #
  # @since 3.0.0
  #
  # @global array $_wp_post_type_features
  #
  # @param [string]       post_type The post type for which to add the feature.
  # @param [string|array] feature   The feature being added, accepts an array of
  #                                 feature strings or a single string.
  def self.add_post_type_support(post_type, feature)
    if feature.is_a? String
      features = [feature]
    else
      features = feature
    end
    GLOBAL._wp_post_type_features ||= {}
    GLOBAL._wp_post_type_features[post_type] ||= {}
    features.each do |feature|
      # TODO how come?? if (func_num_args() == 2)
      GLOBAL._wp_post_type_features[post_type][feature] = true
      # else
      #   Railspress::GLOBAL._wp_post_type_features[post_type][feature] = array_slice(func_get_args(), 2)
      # end
    end
  end

  # Build an object with all post type capabilities out of a post type object
  #
  # Post type capabilities use the 'capability_type' argument as a base, if the
  # capability is not set in the 'capabilities' argument array or if the
  # 'capabilities' argument is not supplied.
  #
  # The capability_type argument can optionally be registered as an array, with
  # the first value being singular and the second plural, e.g. array('story, 'stories')
  # Otherwise, an 's' will be added to the value for the plural form. After
  # registration, capability_type will always be a string of the singular value.
  #
  # By default, seven keys are accepted as part of the capabilities array:
  #
  # - edit_post, read_post, and delete_post are meta capabilities, which are then
  #   generally mapped to corresponding primitive capabilities depending on the
  #   context, which would be the post being edited/read/deleted and the user or
  #   role being checked. Thus these capabilities would generally not be granted
  #   directly to users or roles.
  #
  # - edit_posts - Controls whether objects of this post type can be edited.
  # - edit_others_posts - Controls whether objects of this type owned by other users
  #   can be edited. If the post type does not support an author, then this will
  #   behave like edit_posts.
  # - publish_posts - Controls publishing objects of this post type.
  # - read_private_posts - Controls whether private objects can be read.
  #
  # These four primitive capabilities are checked in core in various locations.
  # There are also seven other primitive capabilities which are not referenced
  # directly in core, except in map_meta_cap(), which takes the three aforementioned
  # meta capabilities and translates them into one or more primitive capabilities
  # that must then be checked against the user or role, depending on the context.
  #
  # - read - Controls whether objects of this post type can be read.
  # - delete_posts - Controls whether objects of this post type can be deleted.
  # - delete_private_posts - Controls whether private objects can be deleted.
  # - delete_published_posts - Controls whether published objects can be deleted.
  # - delete_others_posts - Controls whether objects owned by other users can be
  #   can be deleted. If the post type does not support an author, then this will
  #   behave like delete_posts.
  # - edit_private_posts - Controls whether private objects can be edited.
  # - edit_published_posts - Controls whether published objects can be edited.
  #
  # These additional capabilities are only used in map_meta_cap(). Thus, they are
  # only assigned by default if the post type is registered with the 'map_meta_cap'
  # argument set to true (default is false).
  #
  # @see register_post_type()
  # @see map_meta_cap()
  #
  # @param [object] args Post type registration arguments.
  # @return [object] Object with all the capabilities as member variables.
  def self.get_post_type_capabilities( args )
    unless args['capability_type'].is_a? Array
      args['capability_type'] = [ args['capability_type'], args['capability_type'] + 's' ]
    end

    # Singular base for meta capabilities, plural base for primitive capabilities.
    singular_base, plural_base  = args['capability_type']

    default_capabilities = {
        # Meta capabilities
        'edit_post'          => 'edit_' + singular_base,
        'read_post'          => 'read_' + singular_base,
        'delete_post'        => 'delete_' + singular_base,
        # Primitive capabilities used outside of map_meta_cap():
        'edit_posts'         => 'edit_' + plural_base,
        'edit_others_posts'  => 'edit_others_' + plural_base,
        'publish_posts'      => 'publish_' + plural_base,
        'read_private_posts' => 'read_private_' + plural_base,
    }

    # Primitive capabilities used within map_meta_cap():
    if args['map_meta_cap']
      default_capabilities_for_mapping = {
          'read'                   => 'read',
          'delete_posts'           => 'delete_' + plural_base,
          'delete_private_posts'   => 'delete_private_' + plural_base,
          'delete_published_posts' => 'delete_published_' + plural_base,
          'delete_others_posts'    => 'delete_others_' + plural_base,
          'edit_private_posts'     => 'edit_private_' + plural_base,
          'edit_published_posts'   => 'edit_published_' + plural_base,
      }
      default_capabilities     = default_capabilities.merge(default_capabilities_for_mapping )
    end

    capabilities = default_capabilities.merge(args['capabilities'])

    # Post creation capability simply maps to edit_posts by default:
    if !capabilities['create_posts']
      capabilities['create_posts'] = capabilities['edit_posts']
    end

    # Remember meta capabilities for future reference.
    if args['map_meta_cap']
      _post_type_meta_capabilities( capabilities )
    end

    capabilities
  end

  # Store or return a list of post type meta caps for map_meta_cap().
  #
  # @param [array] capabilities Post type meta capabilities.
  def self._post_type_meta_capabilities(capabilities = nil)
    capabilities.each_pair do |core, custom|
      if ['read_post', 'delete_post', 'edit_post'].include?( core )
        GLOBAL.post_type_meta_caps[ custom ] = core
      end
    end
  end

  # Builds an object with all post type labels out of a post type object.
  #
  # @param [object|WP_Post_Type] post_type_object Post type object.
  # @return object Object with all the labels as member variables.
  def self.get_post_type_labels(post_type_object )
    nohier_vs_hier_defaults              = {
        'name'                     => ["Posts", "Pages"],
        'singular_name'            => ["Post", "Page"],
        # TODO
        # 'add_new'                  => array( _x( 'Add New', 'post' ), _x( 'Add New', 'page' ) ),
        # 'add_new_item'             => array( __( 'Add New Post' ), __( 'Add New Page' ) ),
        # 'edit_item'                => array( __( 'Edit Post' ), __( 'Edit Page' ) ),
        # 'new_item'                 => array( __( 'New Post' ), __( 'New Page' ) ),
        # 'view_item'                => array( __( 'View Post' ), __( 'View Page' ) ),
        # 'view_items'               => array( __( 'View Posts' ), __( 'View Pages' ) ),
        # 'search_items'             => array( __( 'Search Posts' ), __( 'Search Pages' ) ),
        # 'not_found'                => array( __( 'No posts found.' ), __( 'No pages found.' ) ),
        # 'not_found_in_trash'       => array( __( 'No posts found in Trash.' ), __( 'No pages found in Trash.' ) ),
        # 'parent_item_colon'        => array( null, __( 'Parent Page:' ) ),
        # 'all_items'                => array( __( 'All Posts' ), __( 'All Pages' ) ),
        # 'archives'                 => array( __( 'Post Archives' ), __( 'Page Archives' ) ),
        # 'attributes'               => array( __( 'Post Attributes' ), __( 'Page Attributes' ) ),
        # 'insert_into_item'         => array( __( 'Insert into post' ), __( 'Insert into page' ) ),
        # 'uploaded_to_this_item'    => array( __( 'Uploaded to this post' ), __( 'Uploaded to this page' ) ),
        # 'featured_image'           => array( _x( 'Featured Image', 'post' ), _x( 'Featured Image', 'page' ) ),
        # 'set_featured_image'       => array( _x( 'Set featured image', 'post' ), _x( 'Set featured image', 'page' ) ),
        # 'remove_featured_image'    => array( _x( 'Remove featured image', 'post' ), _x( 'Remove featured image', 'page' ) ),
        # 'use_featured_image'       => array( _x( 'Use as featured image', 'post' ), _x( 'Use as featured image', 'page' ) ),
        # 'filter_items_list'        => array( __( 'Filter posts list' ), __( 'Filter pages list' ) ),
        # 'items_list_navigation'    => array( __( 'Posts list navigation' ), __( 'Pages list navigation' ) ),
        # 'items_list'               => array( __( 'Posts list' ), __( 'Pages list' ) ),
        # 'item_published'           => array( __( 'Post published.' ), __( 'Page published.' ) ),
        # 'item_published_privately' => array( __( 'Post published privately.' ), __( 'Page published privately.' ) ),
        # 'item_reverted_to_draft'   => array( __( 'Post reverted to draft.' ), __( 'Page reverted to draft.' ) ),
        # 'item_scheduled'           => array( __( 'Post scheduled.' ), __( 'Page scheduled.' ) ),
        # 'item_updated'             => array( __( 'Post updated.' ), __( 'Page updated.' ) ),
    }
    nohier_vs_hier_defaults['menu_name'] = nohier_vs_hier_defaults['name']

    labels = _get_custom_object_labels( post_type_object, nohier_vs_hier_defaults )

    post_type = post_type_object.name

    default_labels = labels.clone

    # Filters the labels of a specific post type.
    # TODO labels = apply_filters( "post_type_labels_{#{post_type}}", labels)

    # Ensure that the filtered labels contain all required default values.
    default_labels.merge labels
  end

  # Build an object with custom-something object (post type, taxonomy) labels
  # out of a custom-something object
  #
  # @param [object] object                  A custom-something object.
  # @param [array]  nohier_vs_hier_defaults Hierarchical vs non-hierarchical default labels.
  # @return object Object containing labels for the given custom-something object.
  def self._get_custom_object_labels(object, nohier_vs_hier_defaults)
    if !object.label.blank? && object.labels['name'].blank?
      object.labels['name'] = object.label
    end
    if object.labels['singular_name'].blank? && !object.labels['name'].blank?
      object.labels['singular_name'] = object.labels['name']
    end
    object.labels
    # TODO continue
  end

  #  Rails.application.config.middleware.use Railspress::GlobalVars do
  # p "Initializing Railspress - create_initial_post_types..."
  create_initial_post_types

  # p "Initializing Railspress - create_initial_taxonomies..."
  # TODO Railspress::TaxonomyHelper.create_initial_taxonomies
  # end

end