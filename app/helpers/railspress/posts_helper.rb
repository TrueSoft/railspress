=begin
 * Core Post API
 *
 * file wp-includes\post.php
=end
module Railspress::PostsHelper
  include Railspress::Functions
  include Railspress::Plugin
  include Railspress::Load
  include Railspress::PHP

  # Creates the initial post types when 'init' action is fired.
  def self.create_initial_post_types
    register_post_type('post',
                       {
                           'labels' => {
                               'name_admin_bar' => "Post" #  _x('Post', 'add new from admin bar'),
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
                               'name_admin_bar' => "Page" # _x( 'Page', 'add new from admin bar' ),
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
    # register_post_type('custom_css'
    # register_post_type('customize_changeset'
    # register_post_type('oembed_cache'
    # register_post_type('user_request'
    # register_post_type('wp_block'
    # register_post_status(...
  end

  # Registers a post type.
  #
  # @return WP_Post_Type|WP_Error The registered post type object, or an error object.
  def self.register_post_type(post_type, args = {} )
    Railspress.GLOBAL.wp_post_types ||= {}

    # Sanitize post type name
    post_type = Railspress::FormattingHelper.sanitize_key(post_type)

    if  post_type.blank?  || post_type.length > 20
      # _doing_it_wrong( __FUNCTION__, __( 'Post type names must be between 1 and 20 characters in length.' ), '4.2.0' );
      return Railspress::WP_Error.new('post_type_length_invalid', ( 'Post type names must be between 1 and 20 characters in length.' ) )
    end

    post_type_object = Railspress::WpPostType.new(post_type, args)
    post_type_object.add_supports()
    post_type_object.add_rewrite_rules()
    post_type_object.register_meta_boxes()

    Railspress.GLOBAL.wp_post_types[post_type] = post_type_object

    post_type_object.add_hooks()
    post_type_object.register_taxonomies()

    # Fires after a post type is registered.
    # do_action( 'registered_post_type', post_type, post_type_object)

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
  def self.add_post_type_support(post_type, feature, *args)
    if feature.is_a? String
      features = [feature]
    else
      features = feature
    end
    Railspress.GLOBAL._wp_post_type_features ||= {}
    Railspress.GLOBAL._wp_post_type_features[post_type] ||= {}
    features.each do |feature|
      if args.blank?
        Railspress.GLOBAL._wp_post_type_features[post_type][feature] = true
      else
        Railspress.GLOBAL._wp_post_type_features[post_type][feature] = args
      end
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
        Railspress.GLOBAL.post_type_meta_caps[ custom ] = core
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
    labels = Railspress::Plugin.apply_filters( "post_type_labels_{#{post_type}}", labels)

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

  # Retrieve attached file path based on attachment ID.
  #
  # By default the path will go through the 'get_attached_file' filter, but
  # passing a true to the $unfiltered argument of get_attached_file() will
  # return the file path unfiltered.
  #
  # The function works by getting the single post meta name, named
  # '_wp_attached_file' and returning it. This is a convenience function to
  # prevent looking up the meta name and provide a mechanism for sending the
  # attached filename through a filter.
  #
  # @param [int]  attachment_id Attachment ID.
  # @param [bool] unfiltered    Optional. Whether to apply filters. Default false.
  # @return [string|false] The file path to where the attached file should be, false otherwise.
  def get_attached_file(attachment_id, unfiltered = false )
    file = get_post_meta(attachment_id, '_wp_attached_file',true)

    # If the file is relative, prepend upload dir.
    if file && file.index('/') != 0 && !file.match('|^.:\\\|')
      uploads = wp_get_upload_dir
      if uploads && uploads['error'].nil?
        file = uploads['basedir'] + "/#{file}";
      end
    end
    return file if unfiltered
    # Filters the attached file based on the given ID.
    apply_filters( 'get_attached_file', file, attachment_id)
  end

  # Retrieve all children of the post parent ID.
  #
  # @param [mixed]  args   Optional. User defined arguments for replacing the defaults. Default empty.
  # @param [String] output Optional. The required return type. One of OBJECT, ARRAY_A, or ARRAY_N, which correspond to
  #                        a WP_Post object, an associative array, or a numeric array, respectively. Default OBJECT.
  # @return Array of children, where the type of each element is determined by $output parameter. Empty array on failure.
  def get_children(args = '', output = :OBJECT)
    kids = {}
    if args.blank?
        if $GLOBALS['post']
          args = { post_parent:  $GLOBALS['post'].post_parent }
        else
          return kids
        end
    elsif args.is_a? Integer
      args = { post_parent: args}
    elsif args.is_a? String
      args = { post_parent: args.to_i}
    elsif args.is_a? Railspress::WpPost
      args = { post_parent: args.post_parent }
    end

    defaults = {
        numberposts: -1,
        post_type: 'any',
        post_status: 'any',
        post_parent: 0,
    }

    r = defaults.merge args

    children = get_posts(r)

    return kids if children.nil?

    return children unless r[:fields].blank?

    # update_post_cache(children)

    children.each do |child|
      kids[child.id] = child
    end

    if output == :OBJECT
      kids
    elsif output == :ARRAY_A
      weeuns = {}
      kids.values.each do |kid|
        weeuns[kid.id] = kid.attributes
      end
      return weeuns
    elsif output == :ARRAY_N
      babes = {}
      kids.values.each do |kid|
        babes[kid.id] = kid.attributes.values
      end
      return babes
    else
      kids
    end
  end

  # Retrieves post data given a post ID or post object.
  #
  # See sanitize_post() for optional $filter values. Also, the parameter
  # `$post`, must be given as a variable, since it is passed by reference.
  #
  # @param [int|WP_Post|null] post   Optional. Post ID or post object. Defaults to global $post.
  # @param [string]           output Optional. The required return type. One of OBJECT, ARRAY_A, or ARRAY_N, which correspond to
  #                                 a WP_Post object, an associative array, or a numeric array, respectively. Default OBJECT.
  # @param [string]           filter Optional. Type of filter to apply. Accepts 'raw', 'edit', 'db',
  #                                 or 'display'. Default 'raw'.
  # @return [WP_Post|array|null] Type corresponding to $output on success or null on failure.
  #                            When $output is OBJECT, a `WP_Post` instance is returned.
  def get_post(post = nil, output = :OBJECT, filter = 'raw')
    # if ( empty( $post ) && isset( $GLOBALS['post'] ) ) { TODO
    #     $post = $GLOBALS['post'];
    # }

    if  post.is_a? Railspress::WpPost
        _post = post
    elsif post.is_a? Integer
      _post = Railspress::WpPost.find(post)
    elsif post.is_a? String
      _post = Railspress::WpPost.find(post.to_i)
     # elsif ( is_object( $post ) ) TODO
     #  if ( empty( $post->filter ) )
     #    $_post = sanitize_post( $post, 'raw' );
     #    $_post = new WP_Post( $_post );
     #   elsif ( 'raw' == $post->filter )
     #    $_post = new WP_Post( $post );
     #   else
     #    $_post = WP_Post::get_instance( $post->ID );
     #    end
     #  else
     #     $_post = WP_Post::get_instance( $post );
      end

      return nil if _post.nil?

      _post = _post.filter( filter )

      if output == :ARRAY_A
        return _post.attributes
      elsif output == :ARRAY_N
        return _post.attributes.values
      end

      return _post
      end

  # Retrieve the post status based on the post ID.
  #
  # If the post ID is of an attachment, then the parent post status will be given instead.
  #
  # @param [int|WP_Post] post Optional. Post ID or post object. Defaults to global $post..
  # @return [string|false] Post status on success, false on failure.
  def get_post_status(post = nil)
    post = get_post(post)

    return false unless post.is_a? Railspress::WpPost

    if 'attachment' == post.post_type
      return 'private' if 'private' == post.post_status
      # Unattached attachments are assumed to be published.
      return 'publish' if (('inherit' == post.post_status) && (0 == post.post_parent))

      # Inherit status from the parent.
      if post.post_parent && post.id != post.post_parent
        parent_post_status = get_post_status(post.post_parent)
        if 'trash' == parent_post_status
          return get_post_meta(post.post_parent, '_wp_trash_meta_status', true)
        else
          return parent_post_status
        end
      end
    end
    # Filters the post status.
    apply_filters('get_post_status', post.post_status, post)
  end

  # Get extended entry info (<!--more-->).
  #
  # There should not be any space after the second dash and before the word
  # 'more'. There can be text or space(s) after the word 'more', but won't be
  # referenced.
  #
  # The returned array has 'main', 'extended', and 'more_text' keys. Main has the text before
  # the `<!--more-->`. The 'extended' key has the content after the
  # `<!--more-->` comment. The 'more_text' key has the custom "Read More" text.
  #
  # return array Post before ('main'), after ('extended'), and custom read more ('more_text').
  def get_extended(post)
    # Match the new style more links.
    matches = post.scan(/<!--more-->/i)
    if !matches.blank?
      main, extended = post.split(matches[0], 2)
      more_text = matches[1]
    else
      main = post
      extended = ''
      more_text = ''
    end

    # leading and trailing whitespace.
    main = main.gsub(/^[\s]*(.*)[\s]*$/, '\\1')
    extended = extended.gsub(/^[\s]*(.*)[\s]*$/, '\\1')
    more_text = more_text.gsub(/^[\s]*(.*)[\s]*$/, '\\1') unless more_text.nil?

    {main: main, extended: extended, more_text: more_text}
  end

  # Retrieves a post type object by name.
  #
  # @global array $wp_post_types List of post types.
  #
  # @see register_post_type()
  #
  # @param [string] post_type The name of a registered post type.
  # @return WP_Post_Type|null WP_Post_Type object if it exists, null otherwise.
  def get_post_type_object(post_type)

    if !Railspress::PHP.is_scalar(post_type) || Railspress.GLOBAL.wp_post_types[post_type].blank?
      return nil
    end

    Railspress.GLOBAL.wp_post_types[post_type]
  end


  # Get a list of all registered post type objects.
  #
  # @global array $wp_post_types List of post types.
  #
  # @see register_post_type() for accepted arguments.
  #
  # @param [array|string] args     Optional. An array of key => value arguments to match against
  #                                the post type objects. Default empty array.
  # @param [string]       output   Optional. The type of output to return. Accepts post type 'names'
  #                                or 'objects'. Default 'names'.
  # @param [string]       operator Optional. The logical operation to perform. 'or' means only one
  #                                element from the array needs to match; 'and' means all elements
  #                                must match; 'not' means no elements may match. Default 'and'.
  # @return [string[]|WP_Post_Type[]] An array of post type names or objects.
  def get_post_types(args = {}, output = 'names', operator = 'and')
    field = ( 'names' == output ) ? 'name' : false

    wp_filter_object_list(Railspress.GLOBAL.wp_post_types, args, operator, field)
  end

  # Check a post type's support for a given feature.
  #
  # @global array $_wp_post_type_features
  #
  # @param [string] post_type The post type being checked.
  # @param [string] feature   The feature being checked.
  # @return bool Whether the post type supports the given feature.
  def post_type_supports(post_type, feature)
    !Railspress.GLOBAL._wp_post_type_features[post_type][feature].nil?
  end

  # Retrieves an array of the latest posts, or posts matching the given criteria.
  #
  # @param [array] $args {
  #     Optional. Arguments to retrieve posts. See WP_Query::parse_query() for all
  #     available arguments.
  #
  #     @type int        numberposts      Total number of posts to retrieve. Is an alias of $posts_per_page
  #                                        in WP_Query. Accepts -1 for all. Default 5.
  #     @type int|string category         Category ID or comma-separated list of IDs (this or any children).
  #                                       Is an alias of $cat in WP_Query. Default 0.
  #     @type array      include          An array of post IDs to retrieve, sticky posts will be included.
  #                                       Is an alias of $post__in in WP_Query. Default empty array.
  #     @type array      exclude          An array of post IDs not to retrieve. Default empty array.
  #     @type bool       suppress_filters Whether to suppress filters. Default true.
  # }
  # @return Array of post objects or post IDs.
  def get_posts(args = nil)
    defaults = {
        numberposts: 5,
        category: 0,
        orderby: 'date',
        order: 'DESC',
        include: [],
        exclude: [],
        meta_key: '',
        meta_value: '',
        post_type: 'post',
        suppress_filters: true,
    }

    r = defaults.merge(args || {})
    if r[:post_status].blank?
       r[:post_status] = ('attachment' == r[:post_type]) ? 'inherit' : 'publish'
    end
    if !r[:numberposts].blank? && r[:posts_per_page].blank?
       r[:posts_per_page] = r[:numberposts]
    end
    if !r[:category].blank?
        r[:cat] = r[:category]
    end
    if !r[:include].blank?
      incposts           = wp_parse_id_list( r[:include] )
      r[:posts_per_page] = incposts.size # only the number of posts included
      r[:post__in]       = incposts
    elsif  !r[:exclude].blank?
      r[:post__not_in] = wp_parse_id_list( r[:exclude] )
    end

    r[:ignore_sticky_posts] = true
    r[:no_found_rows]       = true

    # $get_posts = new WP_Query;
    # return $get_posts->query( $r );
    where_clause = {post_parent: r[:post_parent], post_type: r[:post_type], post_status: r[:post_status]}
    where_clause[:id] = r[:post__in]  unless r[:post__in].nil?
    Railspress::WpPost.where(where_clause)
        .limit(r[:posts_per_page] == -1 ? nil : r[:posts_per_page])
        .order(r[:orderby] => r[:order].to_sym)
  end

  # Retrieves a post meta field for the given post ID.
  def get_post_meta(post_id, key = '', single = false)
    md = get_metadata('post', post_id, key, single)
    md.symbolize_keys! if md.is_a? Hash
    md
  end

  # Sanitize every post field.
  #
  # If the context is 'raw', then the post object or array will get minimal sanitization of the integer fields.
  #
  # @param [object|WP_Post|array] post    The Post Object or Array
  # @param [string]               context Optional. How to sanitize post fields.
  #                                       Accepts 'raw', 'edit', 'db', or 'display'. Default 'display'.
  # @return object|WP_Post|array The now sanitized Post Object or Array (will be the same type as $post).
  def sanitize_post(post, context = 'display')
    if !post.kind_of?(Hash) # obj??
      # Check if post already filtered for this context.
      return post if post.filter == context
      post.id = 0 if post.id.blank?
      post.attributes.each do |field|
        post.write_attribute(field, sanitize_post_field(field, post.read_attribute(field), post.id, context))
      end
      post.filter = context
    elsif post.kind_of?(Hash)
      # Check if post already filtered for this context.
      return post if post.filter == context
      post['id'] = 0 if post.id.blank?
      post.each {|field, value| post[field] = sanitize_post_field(field, value, post['id'], context)}
      post.filter = context
    end
    return post
  end


 # Sanitize post field based on context.
 #
 # Possible context values are:  'raw', 'edit', 'db', 'display', 'attribute' and
 # 'js'. The 'display' context is used by default. 'attribute' and 'js' contexts
 # are treated like 'display' when calling filters.
 #
 # @param [string] field   The Post Object field name.
 # @param [mixed]  value   The Post Object value.
 # @param [int]    post_id Post ID.
 # @param [string] context Optional. How to sanitize post fields. Looks for 'raw', 'edit',
 #                         'db', 'display', 'attribute' and 'js'. Default 'display'.
 # @return [mixed] Sanitized value.
 def sanitize_post_field(field, value, post_id, context = 'display')
    int_fields = ['ID', 'post_parent', 'menu_order']
    if int_fields.include? field
        value = value.to_i
    end

    # Fields which contain arrays of integers.
    array_int_fields = ['ancestors']
    if array_int_fields.include? field
      value = value.map{|i| i.to_i.abs}
      return value
    end

    return value if 'raw' == context

    prefixed = false
    if field.include? 'post_'
      prefixed        = true
      field_no_prefix = field.gsub('post_', '')
    end

    if 'edit' == context
      format_to_edit = [ 'post_content', 'post_excerpt', 'post_title', 'post_password' ]
      if prefixed
         # Filters the value of a specific post field to edit.
         value = apply_filters("edit_#{field}", value, post_id)
         # Filters the value of a specific post field to edit.
         value = apply_filters( "#{field_no_prefix}_edit_pre", value, post_id )
      else
         value = apply_filters( "edit_post_#{field}", value, post_id )
      end

      if format_to_edit.include?(field)
        if 'post_content' == field
          value = format_to_edit(value, true) # TODO implement function user_can_richedit() from general-template.php
        else
          value = format_to_edit(value)
        end
      else
        value = esc_attr(value)
      end
    elsif 'db' == context
      if prefixed
        # Filters the value of a specific post field before saving.
        value = apply_filters("pre_#{field}", value)
        # Filters the value of a specific field before saving.
        value = apply_filters( "#{field_no_prefix}_save_pre", value )
      else
        value = apply_filters( "pre_post_#{field}", value )
        # Filters the value of a specific post field before saving.
        value = apply_filters( "{$field}_pre", value )
      end
     else
       # Use display filters by default.
       if prefixed
         # Filters the value of a specific post field for display.
         value = apply_filters("{$field}", value, post_id, context)
       else
         value = apply_filters("post_{$field}", value, post_id, context)
       end
       if 'attribute' == context
         value = esc_attr(value)
       elsif 'js' == context
         value = esc_js(value)
       end
     end
    value
   end

  # Retrieves a page given its path.
  #
  # @param [string]       page_path Page path.
  # @param [string]       output    Optional. The required return type. One of OBJECT, ARRAY_A, or ARRAY_N, which correspond to
  #                                 a WP_Post object, an associative array, or a numeric array, respectively. Default OBJECT.
  # @param [string|array] post_type Optional. Post type or array of post types. Default 'page'.
  # @return [WP_Post|array|null] WP_Post (or array) on success, or null on failure.
  def get_page_by_path(page_path, output = :OBJECT, post_type = 'page')
    slugs = page_path.split('/')
    ancestors = []
    p_class = Railspress::WpPost.find_sti_class(post_type)
    page = nil
    begin
      post_parent = 0
      slugs.each do |slug|
        begin
          page = p_class.where(post_name: slug, post_parent: post_parent).first!
          post_parent = page.id
          ancestors << page
        rescue ActiveRecord::RecordNotFound
          page = nil
          break
        end
      end
    rescue ActiveRecord::RecordNotFound
      page = if slugs.size == 1 # retry without considering the parent
               p_class.where(post_name: params[:slug]).first
             else
               nil
             end
    end
    page
  end

  # Build the URI path for a page.
  #
  # Sub pages will be in the "directory" under the parent page post name.
  #
  # @param [WP_Post|object|int] page Optional. Page ID or WP_Post object. Default is global $post.
  # @return [string|false] Page URI, false on error.
  def get_page_uri(page = 0)
    page = get_post(page) unless page.is_a?(Railspress::WpPost)
    return false if page.nil?

    uri = page.post_name

    ancestor = page.parent
    until ancestor.nil?
      uri = ancestor.post_name + '/' + uri unless ancestor.post_name.nil?
      ancestor = ancestor.parent
    end

    # Filters the URI for a page.
    apply_filters('get_page_uri', uri, page)
  end


  # Retrieve attachment meta field for attachment ID.
  #
  # @since 2.1.0
  #
  # @param [int]  attachment_id Attachment post ID. Defaults to global $post.
  # @param [bool] unfiltered    Optional. If true, filters are not run. Default false.
  # @return Attachment meta field. False on failure.
  def wp_get_attachment_metadata(attachment_id = 0, unfiltered = false)
    attachment_id = attachment_id.to_i
    return false unless Railspress::WpPost.exists?(attachment_id)

    data = get_post_meta(attachment_id, '_wp_attachment_metadata', true)

    return data if unfiltered

    # Filters the attachment meta data.
    apply_filters('wp_get_attachment_metadata', data, attachment_id)
  end


  # Retrieve the URL for an attachment.
  #
  # @param [int] attachment_id Optional. Attachment post ID. Defaults to global $post.
  # @return [string|false] Attachment URL, otherwise false.
  def wp_get_attachment_url(attachment_id = 0)
    attachment_id = attachment_id.to_i
    post = get_post(attachment_id)
    return false if post.nil?
    return false if post.post_type != 'attachment'

    url = ''
    # Get attached file.
    if (file = get_post_meta(post.id, '_wp_attached_file', true))
      # Get upload directory.
      uploads = wp_get_upload_dir
      if uploads && !uploads[:error]
        # Check that the upload base exists in the file location.
        if file.index(uploads[:basedir]) == 0
          # Replace file location with url location.
          url = file.gsub(uploads[:basedir], uploads[:baseurl])
        elsif file.include?('wp-content/uploads')
          # Get the directory name relative to the basedir (back compat for pre-2.7 uploads)
          url = trailingslashit(uploads[:baseurl] + '/' + _wp_get_attachment_relative_path(file)) + wp_basename(file)
        else
          # It's a newly-uploaded file, therefore file is relative to the basedir.
          url = uploads[:baseurl] + "/#{file}"
        end
      end
    end

    # If any of the above options failed, Fallback on the GUID as used pre-2.7, not recommended to rely upon this.
    url = get_the_guid(post.id) if url.blank?

    # On SSL front end, URLs should be HTTPS.
    # TODO if is_ssl() && !is_admin() && 'wp-login.php' != $GLOBALS['pagenow']
    #   url = set_url_scheme(url)
    # end

    # Filters the attachment URL.
    url = apply_filters('wp_get_attachment_url', url, post.id)

    return false if url.blank?
    url
  end

  # Retrieve thumbnail for an attachment.
  #
  # @param [int] post_id Optional. Attachment ID. Default 0.
  # @return [string|false] False on failure. Thumbnail file path on success.
  def wp_get_attachment_thumb_file(post_id = 0)
    post_id = post_id.to_i
    post = get_post post_id
    return false if post.nil?

    imagedata = wp_get_attachment_metadata(post.id)
    return false unless imagedata.is_a? Hash
    imagedata.symbolize_keys!

    file = get_attached_file post.id

    unless imagedata[:thumb].blank?
      thumbfile = file.gsub(wp_basename(file), imagedata[:thumb])
      if thumbfile && File.exist?(thumbfile)
        # Filters the attachment thumbnail file path.
        return apply_filters('wp_get_attachment_thumb_file', thumbfile, post.id)
      end
    end
    return false
  end


  # Verifies an attachment is of a given type.
  # @param [String]      type Attachment type. Accepts 'image', 'audio', or 'video'.
  # @param [int|WP_Post] post Optional. Attachment ID or object. Default is global $post.
  # @return [bool] True if one of the accepted types, false otherwise.
  def wp_attachment_is(type, post = nil)
    post = get_post(post)
    return false if post.nil?

    return false if (!file = get_attached_file(post.id))

    return true if post.post_mime_type.index(type + '/') == 0

    check = wp_check_filetype(file)
    return false if check[:ext].blank?

    ext = check[:ext]

    if 'import' != post.post_mime_type
      return type == ext
    end

    case type
    when 'image'
      ['jpg', 'jpeg', 'jpe', 'gif', 'png'].include? ext
    when 'audio'
      wp_get_audio_extensions.include? ext
    when 'video'
      wp_get_video_extensions.include? ext
    else
      type == ext
    end
  end

  # Determines whether an attachment is an image.
  #
  # @param [int|WP_Post] post Optional. Attachment ID or object. Default is global $post.
  # @return [bool] Whether the attachment is an image.
  def wp_attachment_is_image(post = nil)
    return false if post.nil?
    Rails.cache.fetch('Railspress::' + 'Post.' + 'wp_attachment_is_image' + '/' + (((post.is_a?(Integer) || post.is_a?(String))) ? post : post.id).to_s ) {
      wp_attachment_is('image', post)
    }
  end

  # Retrieve the icon for a MIME type.
  #
  # @param [string|int] mime MIME type or attachment ID.
  # @return string|false Icon, false otherwise.
  def wp_mime_type_icon(mime = 0)
      icon = nil
      # if ( ! is_numeric( mime ) ) {
      #     icon = wp_cache_get( "mime_type_icon_$mime" )
      # }

      post_id = 0
      if icon.blank?
        post_mimes = []
        # TODO continue
        # if ( is_numeric( $mime ) ) {
        #     $mime = (int) $mime;
        # if ( $post = get_post( $mime ) ) {
        #     $post_id = (int) $post->ID;
        # $file    = get_attached_file( $post_id );
        # $ext     = preg_replace( '/^.+?\.([^.]+)$/', '$1', $file );
        # if ( ! empty( $ext ) ) {
        #     $post_mimes[] = $ext;
        # if ( $ext_type = wp_ext2type( $ext ) ) {
        #     $post_mimes[] = $ext_type;
        # }
        # }
        # $mime = $post->post_mime_type;
        # } else {
        #     $mime = 0;
        # }
        # } else {
        #     $post_mimes[] = $mime;
        # }
        #
        # $icon_files = wp_cache_get( 'icon_files' );
        #
        # if ( ! is_array( $icon_files ) ) {
        #     # Filters the icon directory path.
        #     $icon_dir = apply_filters( 'icon_dir', ABSPATH + WPINC + '/images/media' );
        #
        # # Filters the icon directory URI.
        # $icon_dir_uri = apply_filters( 'icon_dir_uri', includes_url( 'images/media' ) );
        #
        # # Filters the list of icon directory URIs.
        # $dirs       = apply_filters( 'icon_dirs', array( $icon_dir => $icon_dir_uri ) );
        # $icon_files = array();
        # while ( $dirs ) {
        #     $keys = array_keys( $dirs );
        # $dir  = array_shift( $keys );
        # $uri  = array_shift( $dirs );
        # if ( $dh = opendir( $dir ) ) {
        #     while ( false !== $file = readdir( $dh ) ) {
        #         $file = wp_basename( $file );
        #     if ( substr( $file, 0, 1 ) == '.' ) {
        #         continue;
        #     }
        #     if ( ! in_array( strtolower( substr( $file, -4 ) ), array( '.png', '.gif', '.jpg' ) ) ) {
        #         if ( is_dir( "$dir/$file" ) ) {
        #             $dirs[ "$dir/$file" ] = "$uri/$file";
        #         }
        #         continue;
        #         }
        #         $icon_files[ "$dir/$file" ] = "$uri/$file";
        #         }
        #         closedir( $dh );
        #         }
        #         }
        #         wp_cache_add( 'icon_files', $icon_files, 'default', 600 );
        #         }
        #
        #         types = []
        #         # Icon wp_basename - extension = MIME wildcard.
        #         foreach ( $icon_files as $file => $uri ) {
        #             $types[ preg_replace( '/^([^.]*).*$/', '$1', wp_basename( $file ) ) ] =& $icon_files[ $file ];
        #         }
        #
        #         if ( ! empty( $mime ) ) {
        #             $post_mimes[] = substr( $mime, 0, strpos( $mime, '/' ) );
        #         $post_mimes[] = substr( $mime, strpos( $mime, '/' ) + 1 );
        #         $post_mimes[] = str_replace( '/', '_', $mime );
        #         }
        #
        #         $matches            = wp_match_mime_types( array_keys( $types ), $post_mimes );
        #         $matches['default'] = array( 'default' );
        #
        #         foreach ( $matches as $match => $wilds ) {
        #             foreach ( $wilds as $wild ) {
        #             if ( ! isset( $types[ $wild ] ) ) {
        #             continue;
        #         }
        #
        #         $icon = $types[ $wild ];
        #         if ( ! is_numeric( $mime ) ) {
        #             wp_cache_add( "mime_type_icon_$mime", $icon );
        #         }
        #         break 2;
        #         }
        #         }
        end

        # Filters the mime type icon.
        apply_filters( 'wp_mime_type_icon', icon, mime, post_id )
        end

end
