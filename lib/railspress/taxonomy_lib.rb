=begin
 * Core Taxonomy API
 *
 * file wp-includes\taxonomy.php
=end
require 'railspress/functions'
module Railspress::TaxonomyLib
  include Railspress::Functions
  include Railspress::Plugin

  # Creates the initial taxonomies.
  #
  # This function fires twice: in wp-settings.php before plugins are loaded (for
  # backward compatibility reasons), and again on the {@see 'init'} action. We must
  # avoid registering rewrite rules before the {@see 'init'} action.
  def create_initial_taxonomies
    # TODO if ! did_action( 'init' )  ...
    rewrite = {
        category:    false,
        post_tag:    false,
        post_format: false,
    }
    register_taxonomy('category',
                      'post',
                      {
                          'hierarchical' => true,
                          'query_var' => 'category_name',
                          'rewrite' => rewrite[:category],
                          'public' => true,
                          'show_ui' => true,
                          'show_admin_column' => true,
                          '_builtin' => true,
                          'capabilities' => {
                              'manage_terms' => 'manage_categories',
                              'edit_terms' => 'edit_categories',
                              'delete_terms' => 'delete_categories',
                              'assign_terms' => 'assign_categories',
                          },
                          'show_in_rest' => true,
                          'rest_base' => 'categories',
                          'rest_controller_class' => 'WP_REST_Terms_Controller',
                      }
    )
    register_taxonomy('post_tag',
                      'post',
                      {
                          'hierarchical' => false,
                          'query_var' => 'tag',
                          'rewrite' => rewrite[:post_tag],
                          'public' => true,
                          'show_ui' => true,
                          'show_admin_column' => true,
                          '_builtin' => true,
                          'capabilities' => {
                              'manage_terms' => 'manage_post_tags',
                              'edit_terms' => 'edit_post_tags',
                              'delete_terms' => 'delete_post_tags',
                              'assign_terms' => 'assign_post_tags',
                          },
                          'show_in_rest' => true,
                          'rest_base' => 'tags',
                          'rest_controller_class' => 'WP_REST_Terms_Controller',
                      }
    )
    register_taxonomy('nav_menu',
                      'nav_menu_item',
                      {
                          'public' => false,
                          'hierarchical' => false,
                          'labels' => {
                              # 'name'          => __( 'Navigation Menus' ),
                              # 'singular_name' => __( 'Navigation Menu' ),
                          },
                          'query_var' => false,
                          'rewrite' => false,
                          'show_ui' => false,
                          '_builtin' => true,
                          'show_in_nav_menus' => false,
                      }
    )
    register_taxonomy('link_category',
                      'link',
                      {
                          'hierarchical' => false,
                          'labels' => {
                              # 'name'                       => __( 'Link Categories' ),
                              # 'singular_name'              => __( 'Link Category' ),
                              # 'search_items'               => __( 'Search Link Categories' ),
                              # 'popular_items'              => null,
                              # 'all_items'                  => __( 'All Link Categories' ),
                              # 'edit_item'                  => __( 'Edit Link Category' ),
                              # 'update_item'                => __( 'Update Link Category' ),
                              # 'add_new_item'               => __( 'Add New Link Category' ),
                              # 'new_item_name'              => __( 'New Link Category Name' ),
                              # 'separate_items_with_commas' => null,
                              # 'add_or_remove_items'        => null,
                              # 'choose_from_most_used'      => null,
                              # 'back_to_items'              => __( '&larr; Back to Link Categories' ),
                          },
                          'capabilities' => {
                              'manage_terms' => 'manage_links',
                              'edit_terms' => 'manage_links',
                              'delete_terms' => 'manage_links',
                              'assign_terms' => 'manage_links',
                          },
                          'query_var' => false,
                          'rewrite' => false,
                          'public' => false,
                          'show_ui' => true,
                          '_builtin' => true,
                      }
    )
    register_taxonomy('post_format',
                      'post',
                      {
                          'public'            => true,
                          'hierarchical'      => false,
                          'labels'            => {
                              # 'name'          => _x( 'Formats', 'post format' ),
                              # 'singular_name' => _x( 'Format', 'post format' ),
                          },
                          'query_var'         => true,
                          'rewrite'           => rewrite[:post_format],
                          'show_ui'           => false,
                          '_builtin'          => true,
                      # TODO    'show_in_nav_menus' => current_theme_supports( 'post-formats' )
                      }
    )
  end

  # Retrieves a list of registered taxonomy names or objects.
  #
  # @param [array]  args     Optional. A hash of `key => value` arguments to match against the taxonomy objects.
  #                          Default empty hash.
  # @param [string] output   Optional. The type of output to return in the array. Accepts either taxonomy 'names'
  #                          or 'objects'. Default 'names'.
  # @param [string] operator Optional. The logical operation to perform. Accepts 'and' or 'or'. 'or' means only
  #                          one element from the array needs to match; 'and' means all elements must match.
  #                          Default 'and'.
  # @return string[]|WP_Taxonomy[] An array of taxonomy names or objects.
  def get_taxonomies( args = {}, output = 'names', operator = 'and' )
    if output == 'names'
      names = []
      Railspress::Taxonomy.where(args).all.each do |tax|
        names << tax.name
      end
      names
    else
      Railspress::Taxonomy.where(args)
    end
    # TODO continue get_taxonomies()
  end

  # Return the names or objects of the taxonomies which are registered for the requested object or object type, such as
  # a post object or post type name.
  #
  # Example:
  #
  #     taxonomies = get_object_taxonomies('post')
  #
  # This results in:
  #
  #     ['category', 'post_tag']
  #
  # @param [array|string|WP_Post] $object Name of the type of taxonomy object, or an object (row from posts)
  # @param [string]               $output Optional. The type of output to return in the array. Accepts either
  #                                     taxonomy 'names' or 'objects'. Default 'names'.
  # @return array The names of all taxonomy of $object_type.
  def get_object_taxonomies(object, output = 'names')
    if object.is_a? Railspress::WpPost
      return get_attachment_taxonomies(object, output) if (object.post_type == 'attachment')
      object = object.post_type
    end

    object = [object]

    taxonomies = 'names' == output ? [] : {}
    Railspress::Taxonomy.all.each do |tax|
      tax_name, tax_obj = tax.name, tax
      # unless (object & tax_obj.object_type.to_a).blank?  TODO taxonomy object_type
      #   if 'names' == output
      #     taxonomies << tax_name
      #   else
      #     taxonomies[tax_name] = tax_obj
      #   end
      # end
    end
    taxonomies
  end

  # Retrieves the taxonomy object of taxonomy.
  #
  # The get_taxonomy function will first check that the parameter string given
  # is a taxonomy object and if it is, it will return it.
  #
  # @global array $wp_taxonomies The registered taxonomies.
  #
  # @param [String] taxonomy Name of taxonomy object to return.
  # @return WP_Taxonomy|false The Taxonomy Object or false if $taxonomy doesn't exist.
  def get_taxonomy(taxonomy)
    # global $wp_taxonomies

    # return false unless taxonomy_exists(taxonomy)
    global_tax = Railspress.GLOBAL.wp_taxonomies[taxonomy]
    return global_tax unless global_tax.nil?

    Railspress::Taxonomy.where(taxonomy: taxonomy).all
  end

  # Determines whether the taxonomy name exists.
  #
  # Formerly is_taxonomy(), introduced in 2.3.0.
  #
  # For more information on this and similar theme functions, check out
  # the {@link https://developer.wordpress.org/themes/basics/conditional-tags/
  # Conditional Tags} article in the Theme Developer Handbook.
  #
  # @param [String] taxonomy Name of taxonomy object.
  # @return bool Whether the taxonomy exists.
  def taxonomy_exists(taxonomy)
    return true unless Railspress.GLOBAL.wp_taxonomies[taxonomy].nil?
    Railspress::Taxonomy.exists? taxonomy: taxonomy
  end

  # Creates or modifies a taxonomy object.
  #
  # Note: Do not use before the {@see 'init'} hook.
  #
  # A simple function for creating or modifying a taxonomy object based on
  # the parameters given. If modifying an existing taxonomy object, note
  # that the `$object_type` value from the original registration will be
  # overwritten.
  # @param [string]       taxonomy    Taxonomy key, must not exceed 32 characters.
  # @param [array|string] object_type Object type or array of object types with which the taxonomy should be associated.
  # @param [array|string] args        {
  #     Optional. Array or query string of arguments for registering a taxonomy.
  #
  #     @type array         $labels                An array of labels for this taxonomy. By default, Tag labels are
  #                                                used for non-hierarchical taxonomies, and Category labels are used
  #                                                for hierarchical taxonomies. See accepted values in
  #                                                get_taxonomy_labels(). Default empty array.
  #     @type string        $description           A short descriptive summary of what the taxonomy is for. Default empty.
  #     @type bool          $public                Whether a taxonomy is intended for use publicly either via
  #                                                the admin interface or by front-end users. The default settings
  #                                                of `$publicly_queryable`, `$show_ui`, and `$show_in_nav_menus`
  #                                                are inherited from `$public`.
  #     @type bool          $publicly_queryable    Whether the taxonomy is publicly queryable.
  #                                                If not set, the default is inherited from `$public`
  #     @type bool          $hierarchical          Whether the taxonomy is hierarchical. Default false.
  #     @type bool          $show_ui               Whether to generate and allow a UI for managing terms in this taxonomy in
  #                                                the admin. If not set, the default is inherited from `$public`
  #                                                (default true).
  #     @type bool          $show_in_menu          Whether to show the taxonomy in the admin menu. If true, the taxonomy is
  #                                                shown as a submenu of the object type menu. If false, no menu is shown.
  #                                                `$show_ui` must be true. If not set, default is inherited from `$show_ui`
  #                                                (default true).
  #     @type bool          $show_in_nav_menus     Makes this taxonomy available for selection in navigation menus. If not
  #                                                set, the default is inherited from `$public` (default true).
  #     @type bool          $show_in_rest          Whether to include the taxonomy in the REST API.
  #     @type string        $rest_base             To change the base url of REST API route. Default is $taxonomy.
  #     @type string        $rest_controller_class REST API Controller class name. Default is 'WP_REST_Terms_Controller'.
  #     @type bool          $show_tagcloud         Whether to list the taxonomy in the Tag Cloud Widget controls. If not set,
  #                                                the default is inherited from `$show_ui` (default true).
  #     @type bool          $show_in_quick_edit    Whether to show the taxonomy in the quick/bulk edit panel. It not set,
  #                                                the default is inherited from `$show_ui` (default true).
  #     @type bool          $show_admin_column     Whether to display a column for the taxonomy on its post type listing
  #                                                screens. Default false.
  #     @type bool|callable $meta_box_cb           Provide a callback function for the meta box display. If not set,
  #                                                post_categories_meta_box() is used for hierarchical taxonomies, and
  #                                                post_tags_meta_box() is used for non-hierarchical. If false, no meta
  #                                                box is shown.
  #     @type callable      $meta_box_sanitize_cb  Callback function for sanitizing taxonomy data saved from a meta
  #                                                box. If no callback is defined, an appropriate one is determined
  #                                                based on the value of `$meta_box_cb`.
  #     @type array         $capabilities {
  #         Array of capabilities for this taxonomy.
  #
  #         @type string $manage_terms Default 'manage_categories'.
  #         @type string $edit_terms   Default 'manage_categories'.
  #         @type string $delete_terms Default 'manage_categories'.
  #         @type string $assign_terms Default 'edit_posts'.
  #     }
  #     @type bool|array    $rewrite {
  #         Triggers the handling of rewrites for this taxonomy. Default true, using $taxonomy as slug. To prevent
  #         rewrite, set to false. To specify rewrite rules, an array can be passed with any of these keys:
  #
  #         @type string $slug         Customize the permastruct slug. Default `$taxonomy` key.
  #         @type bool   $with_front   Should the permastruct be prepended with WP_Rewrite::$front. Default true.
  #         @type bool   $hierarchical Either hierarchical rewrite tag or not. Default false.
  #         @type int    $ep_mask      Assign an endpoint mask. Default `EP_NONE`.
  #     }
  #     @type string        $query_var             Sets the query var key for this taxonomy. Default `$taxonomy` key. If
  #                                                false, a taxonomy cannot be loaded at `?{query_var}={term_slug}`. If a
  #                                                string, the query `?{query_var}={term_slug}` will be valid.
  #     @type callable      $update_count_callback Works much like a hook, in that it will be called when the count is
  #                                                updated. Default _update_post_term_count() for taxonomies attached
  #                                                to post types, which confirms that the objects are published before
  #                                                counting them. Default _update_generic_term_count() for taxonomies
  #                                                attached to other object types, such as users.
  #     @type bool          $_builtin              This taxonomy is a "built-in" taxonomy. INTERNAL USE ONLY!
  #                                                Default false.
  # }
  # @return WP_Error|void WP_Error, if errors.
  def register_taxonomy(taxonomy, object_type, args = {})
    Railspress.GLOBAL.wp_taxonomies = {} if Railspress.GLOBAL.wp_taxonomies.nil?
    args = Railspress::Functions.wp_parse_args( args )

    if ( taxonomy.blank? || taxonomy.length > 32 )
      # _doing_it_wrong( __FUNCTION__, __( 'Taxonomy names must be between 1 and 32 characters in length.' ), '4.2.0' )
      return Railspress::WP_Error.new( 'taxonomy_length_invalid', ( 'Taxonomy names must be between 1 and 32 characters in length.' ) )
    end
    # TODO continue WP_Taxonomy

    taxonomy_object = Railspress::Taxonomy.new({taxonomy: taxonomy})
    taxonomy_object.set_props(object_type, args)
    taxonomy_object.add_rewrite_rules

    Railspress.GLOBAL.wp_taxonomies[ taxonomy ] = taxonomy_object

    taxonomy_object.add_hooks

    # Fires after a taxonomy is registered.
    do_action( 'registered_taxonomy', taxonomy, object_type, taxonomy_object)
  end

  # TODO unregister_taxonomy()

  # Add an already registered taxonomy to an object type.
  #
  # @global array $wp_taxonomies The registered taxonomies.
  #
  # @param [string] taxonomy    Name of taxonomy object.
  # @param [string] object_type Name of the object type.
  # @return bool True if successful, false if not.
  def register_taxonomy_for_object_type(taxonomy, object_type)

    return false if Railspress.GLOBAL.wp_taxonomies[taxonomy].nil?
    return false if !get_post_type_object(object_type)

    unless Railspress.GLOBAL.wp_taxonomies[ taxonomy ].object_type.include?( object_type )
      Railspress.GLOBAL.wp_taxonomies[ taxonomy ].object_type << object_type
    end

    # Filter out empties.
    Railspress.GLOBAL.wp_taxonomies[ taxonomy ].object_type.select! {|ot| !ot.blank? }

    # Fires after a taxonomy is registered for an object type.
    do_action( 'registered_taxonomy_for_object_type', taxonomy, object_type)

    true
  end

  # Remove an already registered taxonomy from an object type.
  #
  # @param [string] taxonomy    Name of taxonomy object.
  # @param [string] object_type Name of the object type.
  # @return [bool] True if successful, false if not.
  def unregister_taxonomy_for_object_type(taxonomy, object_type)
    return false if Railspress.GLOBAL.wp_taxonomies[taxonomy].nil?
    return false if !get_post_type_object(object_type)

    if Railspress.GLOBAL.wp_taxonomies[taxonomy].object_type.include? object_type
      Railspress.GLOBAL.wp_taxonomies[taxonomy].object_type.delete(object_type)
    else
      return false
    end

    # Fires after a taxonomy is unregistered for an object type.
    do_action('unregistered_taxonomy_for_object_type', taxonomy, object_type)

    true
  end

  ##
  ## Term API
  ##

  # Get all Term data from database by Term ID.
  #
  # The usage of the get_term function is to apply filters to a term object. It
  # is possible to get a term object from the database before applying the
  # filters.
  #
  # $term ID must be part of $taxonomy, to get from the database. Failure, might
  # be able to be captured by the hooks. Failure would be the same value as $wpdb
  # returns for the get_row method.
  #
  # There are two hooks, one is specifically for each term, named 'get_term', and
  # the second is for the taxonomy name, 'term_$taxonomy'. Both hooks gets the
  # term object, and the taxonomy name as parameters. Both hooks are expected to
  # return a Term object.
  #
  # {@see 'get_term'} hook - Takes two parameters the term Object and the taxonomy name.
  # Must return term object. Used in get_term() as a catch-all filter for every
  # $term.
  #
  # {@see 'get_$taxonomy'} hook - Takes two parameters the term Object and the taxonomy
  # name. Must return term object. $taxonomy will be the taxonomy name, so for
  # example, if 'category', it would be 'get_category' as the filter name. Useful
  # for custom taxonomies or plugging into default taxonomies.
  #
  # @see sanitize_term_field() The $context param lists the available values for get_term_by() $filter param.
  #
  # @param [int|WP_Term|object] term If integer, term data will be fetched from the database, or from the cache if
  #                                  available. If stdClass object (as in the results of a database query), will apply
  #                                  filters and return a `WP_Term` object corresponding to the `$term` data. If `WP_Term`,
  #                                  will return `$term`.
  # @param [string]     taxonomy Optional. Taxonomy name that $term is part of.
  # @param [string]     output   Optional. The required return type. One of OBJECT, ARRAY_A, or ARRAY_N, which correspond to
  #                              a WP_Term object, an associative array, or a numeric array, respectively. Default OBJECT.
  # @param [string]     filter   Optional, default is raw or no WordPress defined filter will applied.
  # @return array|WP_Term|WP_Error|null Object of the type specified by `$output` on success. When `$output` is 'OBJECT',
  #                                     a WP_Term instance is returned. If taxonomy does not exist, a WP_Error is
  #                                     returned. Returns null for miscellaneous failure.
  def get_term(term, taxonomy = '', output = :OBJECT, filter = 'raw' )
    return WP_Error.new('invalid_term', I18n.t('railspress.invalid_term')) if term.blank?

    if !taxonomy.blank? && !taxonomy_exists(taxonomy)
      return WP_Error.new('invalid_taxonomy', I18n.t('railspress.invalid_taxonomy'))
    end

    if term.is_a? Railspress::Term
      _term = term
    elsif !term.is_a?(Integer)
      if term.filter.blank? || 'raw' == term.filter
        _term = sanitize_term(term, taxonomy, 'raw')
        _term = Railspress::Term.new(_term)
      else
        _term = Railspress::Term.find(term.term_id)
      end
    else
      _term = Railspress::Term.find(term.to_i)
    end

    if _term.is_a? Railspress::WP_Error
      return _term
    elsif _term.nil?
      return nil
    end

    # Ensure for filters that this is not empty.
    taxonomy = _term.taxonomy.taxonomy

    # Filters a taxonomy term object.
    _term = apply_filters('get_term', _term, taxonomy)

    # Filters a taxonomy term object.
    _term = apply_filters("get_#{taxonomy}", _term, taxonomy)

    # Bail if a filter callback has changed the type of the `$_term` object.
    return _term unless _term.is_a? Railspress::Term

    # Sanitize term, according to the specified filter.
    _term.filter(filter)

    # TODO :ARRAY_A / :ARRAY_N
    if output == :ARRAY_A
      return _term.to_array()
    elsif output == :ARRAY_N
      return array_values(_term.to_array())
    end

    _term
  end

  # Get all Term data from database by Term field and data.
  #
  # Warning: $value is not escaped for 'name' $field. You must do it yourself, if
  # required.
  #
  # The default $field is 'id', therefore it is possible to also use null for
  # field, but not recommended that you do so.
  #
  # If $value does not exist, the return value will be false. If $taxonomy exists
  # and $field and $value combinations exist, the Term will be returned.
  #
  # This function will always return the first term that matches the `$field`-
  # `$value`-`$taxonomy` combination specified in the parameters. If your query
  # is likely to match more than one term (as is likely to be the case when
  # `$field` is 'name', for example), consider using get_terms() instead; that
  # way, you will get all matching terms, and can provide your own logic for
  # deciding which one was intended.
  #
  # @see sanitize_term_field() The $context param lists the available values for get_term_by() $filter param.
  #
  # @param [string]     field    Either 'slug', 'name', 'id' (term_id), or 'term_taxonomy_id'
  # @param [string|int] value    Search for this term value
  # @param [string]     taxonomy Taxonomy name. Optional, if `$field` is 'term_taxonomy_id'.
  # @param [string]     output   Optional. The required return type. One of OBJECT, ARRAY_A, or ARRAY_N, which correspond to
  #                              a WP_Term object, an associative array, or a numeric array, respectively. Default OBJECT.
  # @param [string]     filter   Optional, default is raw or no WordPress defined filter will applied.
  # @return [WP_Term|array|false] WP_Term instance (or array) on success. Will return false if `$taxonomy` does not exist
  #                              or `$term` was not found.
  def get_term_by(field, value, taxonomy = '', output = :OBJECT, filter = 'raw' )

    # 'term_taxonomy_id' lookups don't require taxonomy checks.
    if :term_taxonomy_id != field && !taxonomy_exists(taxonomy)
      return false
    end

    # No need to perform a query for empty 'slug' or 'name'.
    if :slug == field || :name == field
      value = value.to_s

      return false if value == ''
    end

    if :id == field || :term_id == field
      term = get_term(value.to_i, taxonomy, output, filter)

      term = false if term.is_a?(Railspress::WP_Error) || term.nil?

      return term
    end

    args = {
        get:                    'all',
        number:                 1,
        taxonomy:               taxonomy,
        update_term_meta_cache: false,
        orderby:                'none',
        suppress_filter:        true
    }

    case field
    when :slug
      args[:slug] = value
    when :name
      args[:name] = value
    when :term_taxonomy_id
      args[:term_taxonomy_id] = value
      args.remove :taxonomy
    else
      return false
    end

    terms = get_terms(args)
    return false  if  terms.is_a?(Railspress::WP_Error) || terms.blank?

    term = terms.to_a.shift

    # In the case of 'term_taxonomy_id', override the provided `$taxonomy` with whatever we find in the db.
    if :term_taxonomy_id == field
      taxonomy = term.taxonomy
    end

    get_term(term, taxonomy, output, filter)
  end

  # Retrieve the terms in a given taxonomy or list of taxonomies.
  #
  # You can fully inject any customizations to the query before it is sent, as
  # well as control the output with a filter.
  #
  # The {@see 'get_terms'} filter will be called when the cache has the term and will
  # pass the found term along with the array of $taxonomies and array of $args.
  # This filter is also called before the array of terms is passed and will pass
  # the array of terms, along with the $taxonomies and $args.
  #
  # The {@see 'list_terms_exclusions'} filter passes the compiled exclusions along with
  # the $args.
  #
  # The {@see 'get_terms_orderby'} filter passes the `ORDER BY` clause for the query
  # along with the $args array.
  #
  # @param [string|array] args       Optional. Array or string of arguments. See WP_Term_Query::__construct()
  #                                  for information on accepted arguments. Default empty.
  # @return [array|int|WP_Error] List of WP_Term instances and their children. Will return WP_Error, if any of $taxonomies
  #                              do not exist.
  def get_terms(args = {})
    term_query = {} # WP_Term_Query();

    defaults = {
        suppress_filter: false
    }

    args = Railspress::Functions.wp_parse_args(args, defaults)
    unless args[:taxonomy].nil?
      args[:taxonomy] =  [args[:taxonomy]]
    end

    unless args[:taxonomy].empty?
      args[:taxonomy].each do |taxonomy|
        return WP_Error.new('invalid_taxonomy', I18n.t('railspress.invalid_taxonomy')) unless taxonomy_exists(taxonomy)
      end
    end

    # Don't pass suppress_filter to WP_Term_Query.
    suppress_filter = args[:suppress_filter]
    args.delete(:suppress_filter)

    where_cond = args.slice(:slug, :name, :term_taxonomy_id)
    case args[:get]
    when 'all'
      terms = Railspress::Term.where(where_cond).all
    when 'count'
      terms = Railspress::Term.where(where_cond).count
    end

    # Count queries are not filtered, for legacy reasons.
    return terms unless terms.is_a? Array

    return terms if suppress_filter

    # Filters the found terms.
    apply_filters('get_terms', terms, term_query.query_vars['taxonomy'], term_query.query_vars, term_query)
  end


  # Sanitize Term all fields.
  #
  # Relies on sanitize_term_field() to sanitize the term. The difference is that
  # this function will sanitize <strong>all</strong> fields. The context is based
  # on sanitize_term_field().
  #
  # The $term is expected to be either an array or an object.
  #
  # @since 2.3.0
  #
  # @param [array|object] term     The term to check.
  # @param [string]       taxonomy The taxonomy name to use.
  # @param [string]       context  Optional. Context in which to sanitize the term. Accepts 'edit', 'db',
  #                                'display', 'attribute', or 'js'. Default 'display'.
  # @return [array|object] Term with all fields sanitized.
  def sanitize_term(term, taxonomy, context = 'display')
    # fields = ['term_id', 'name', 'description', 'slug', 'count', 'parent', 'term_group', 'term_taxonomy_id', 'object_id' ]

    do_object = !term.kind_of?(Hash)

    term_id = do_object ? term.term_id : (term['term_id'] || 0)

    term.attributes.each do |field|

      if do_object
        if !term.read_attribute(field).nil?
          term.write_attribute(field, sanitize_term_field(field, term.read_attribute(field), term_id, taxonomy, context))
        end
      else
        if !term[field].nil?
          term[field] = sanitize_term_field(field, term[field], term_id, taxonomy, context)
        end
      end
    end

    if do_object
      term.filter_str = context
    else
      term['filter'] = context
    end

    term
  end

  # Cleanse the field value in the term based on the context.
  #
  # Passing a term field value through the function should be assumed to have
  # cleansed the value for whatever context the term field is going to be used.
  #
  # If no context or an unsupported context is given, then default filters will
  # be applied.
  #
  # There are enough filters for each context to support a custom filtering
  # without creating your own filter function. Simply create a function that
  # hooks into the filter you need.
  #
  # @since 2.3.0
  #
  # @param [string] field    Term field to sanitize.
  # @param [string] value    Search for this term value.
  # @param [int]    term_id  Term ID.
  # @param [string] taxonomy Taxonomy Name.
  # @param [string] context  Context in which to sanitize the term field. Accepts 'edit', 'db', 'display',
  #                          'attribute', or 'js'.
  # @return mixed Sanitized field.
  def sanitize_term_field(field, value, term_id, taxonomy, context)
    int_fields = [:parent, :term_id, :count, :term_group, :term_taxonomy_id, :object_id]
    if int_fields.include? field
      value = value.to_i
      value = 0 if value < 0
    end

    return value if 'raw' == context

    if 'edit' == context

      # Filters a term field to edit before it is sanitized.
      value = apply_filters("edit_term_#{field}", value, term_id, taxonomy)

      # Filters the taxonomy field to edit before it is sanitized.
      value = apply_filters("edit_#{taxonomy}_#{field}", value, term_id)

      if 'description' == field
        value = esc_html(value) # textarea_escaped
      else
        value = esc_attr(value)
      end
    elsif 'db' == context

      # Filters a term field value before it is sanitized.
      value = apply_filters("pre_term_#{field}", value, taxonomy)

      # Filters a taxonomy field before it is sanitized.
      value = apply_filters("pre_#{taxonomy}_#{field}", value)

      # Back compat filters
      if :slug == field
        # Filters the category nicename before it is sanitized.
        value = apply_filters('pre_category_nicename', value)
      end
    elsif 'rss' == context

      # Filters the term field for use in RSS.
      value = apply_filters("term_#{field}_rss", value, taxonomy)

      # Filters the taxonomy field for use in RSS.
      value = apply_filters("#{taxonomy}_#{field}_rss", value)
    else
      # Use display filters by default.

      # Filters the term field sanitized for display.
      value = apply_filters("term_#{field}", value, term_id, taxonomy, context)

      # Filters the taxonomy field sanitized for display.
      value = apply_filters("#{taxonomy}_#{field}", value, term_id, context)
    end

    if 'attribute' == context
      value = esc_attr(value)
    elsif 'js' == context
      value = esc_js(value)
    end
    value
  end

  # Retrieves the terms associated with the given object(s), in the supplied taxonomies.
  #
  # @param [int|array]    object_ids The ID(s) of the object(s) to retrieve.
  # @param [string|array] taxonomies The taxonomies to retrieve terms from.
  # @param [array|string] args       See WP_Term_Query::__construct() for supported arguments.
  # @return [array|WP_Error] The requested term data or empty array if no terms found.
  #                        WP_Error if any of the taxonomies don't exist.
  def wp_get_object_terms(object_ids, taxonomies, args = {})
    return {} if object_ids.blank? or taxonomies.blank?

    unless taxonomies.is_a? Array
      taxonomies = [taxonomies]
    end

    # taxonomies.each do |taxonomy|
    #   unless taxonomy_exists(taxonomy)
    #     p "Taxonomy #{taxonomy} is invalid in #{taxonomies}"
    #     raise WP_Error.new('invalid_taxonomy', I18n.t('railspress.invalid_taxonomy'))
    #   end
    # end

    unless object_ids.is_a? Array
      object_ids = [object_ids]
    end
    object_ids = object_ids.map(&:to_i)

    args = Railspress::Functions.wp_parse_args(args)

    # Filter arguments for retrieving object terms.
    args = apply_filters('wp_get_object_terms_args', args, object_ids, taxonomies)

    # When one or more queried taxonomies is registered with an 'args' array,
    # those params override the `args` passed to this function.
    terms = []

    # added:
    if true
      taxonomies.each_with_index do |taxonomy, index|
        # terms += get_taxonomy(taxonomy)
        terms += Railspress::Taxonomy.joins(:posts).where(Railspress::Post.table_name => {id: object_ids}, taxonomy: taxonomy)
      end
      return terms # .select{|term_obj| object_ids.include? term_obj.post.id }
    end

    # TODO ???
    if taxonomies.size > 1
      taxonomies.each_with_index do |taxonomy, index|

        t = get_taxonomy(taxonomy)
        if !t.args.blank? && t.args.is_a?(Hash) && args != args.merge(t.args)
          taxonomies[index] = nil
          terms += wp_get_object_terms(object_ids, taxonomy, args.merge(t.args))
        end
      end
    else
      t = get_taxonomy(taxonomies[0])
      if !t.args.blank? && t.args.is_a?(Hash)
        args = args.merge t.args
      end
    end

    args['taxonomy'] = taxonomies
    args['object_ids'] = object_ids

    # Taxonomies registered without an 'args' param are handled here.
    if !taxonomies.blank?
      terms_from_remaining_taxonomies = get_terms(args)

      # Array keys should be preserved for values of fields that use term_id for keys.
      if !args['fields'].blank? && 0 == args['fields'].index('id=>')
        terms = terms + terms_from_remaining_taxonomies
      else
        terms = terms.merge terms_from_remaining_taxonomies
      end
    end

    # Filters the terms for a given object or objects.
    terms = apply_filters('get_object_terms', terms, object_ids, taxonomies, args)

    object_ids = object_ids.join(',')
    taxonomies.map(&:esc_url)
    taxonomies = "'" + taxonomies.map(&:esc_sql).join("', '") + "'"

    # Filters the terms for a given object or objects.
    apply_filters('wp_get_object_terms', terms, object_ids, taxonomies, args)
  end

  # Generate a permalink for a taxonomy term archive.
  #
  # @global WP_Rewrite $wp_rewrite
  #
  # @param [object|int|string] term     The term object, ID, or slug whose link will be retrieved.
  # @param [string]            taxonomy Optional. Taxonomy. Default empty.
  # @return [string|WP_Error] HTML link to taxonomy term archive on success, WP_Error if term does not exist.
  def get_term_link(term, taxonomy = '')
    # global $wp_rewrite;

    unless term.is_a? Railspress::Term
      if term.is_a? Integer
        term = get_term(term, taxonomy)
      elsif term.is_a? Railspress::PostTag
        term = get_term_by(:slug, term.term.slug, taxonomy)
      else
        term = get_term_by(:slug, term, taxonomy)
      end
    end
    if term.blank?
      term = Railspress::WP_Error.new('invalid_term', I18n.t('railspress.invalid_term'))
    end

    return term if term.is_a? Railspress::WP_Error

    taxonomy = term.taxonomy

    termlink = 'news/tag/%post_tag%' # TODO GLOBAL.wp_rewrite.get_extra_permastruct(taxonomy)

    # Filters the permalink structure for a terms before token replacement occurs.
    termlink = apply_filters('pre_term_link', termlink, term)

    slug = term.slug
    t    = get_taxonomy(taxonomy)

    if termlink.blank?
      if 'category' == taxonomy
        termlink = {cat: term.term_id} # '?cat=' + term.term_id
        # elsif t.query_var
        #    termlink = "?$t->query_var=$slug";
      else
        termlink = {taxonomy: taxonomy, term: slug} # "?taxonomy=$taxonomy&term=$slug";
      end
      termlink = main_app.root_url(termlink)
    else
      if false # TODO t.rewrite['hierarchical']
        # $hierarchical_slugs = array();
        # $ancestors          = get_ancestors( $term->term_id, $taxonomy, 'taxonomy' );
        # foreach ( (array) $ancestors as $ancestor ) {
        #     $ancestor_term        = get_term( $ancestor, $taxonomy );
        # $hierarchical_slugs[] = $ancestor_term->slug;
        # }
        # $hierarchical_slugs   = array_reverse( $hierarchical_slugs );
        # $hierarchical_slugs[] = $slug;
        # $termlink             = str_replace( "%$taxonomy%", implode( '/', $hierarchical_slugs ), $termlink );
      else
        termlink = termlink.gsub("%#{taxonomy.taxonomy}%", slug)
      end
      termlink = main_app.root_url + termlink # home_url( user_trailingslashit( termlink, 'category' ) )
    end
    # Back Compat filters.
    if 'post_tag' == taxonomy

      # Filters the tag link.
      termlink = apply_filters('tag_link', termlink, term.term_id)
    elsif 'category' == taxonomy

      # Filters the category link.
      termlink = apply_filters('category_link', termlink, term.term_id)
    end

    # Filters the term link.
    apply_filters( 'term_link', termlink, term, taxonomy )
  end

  # TODO the_taxonomies, get_the_taxonomies, get_post_taxonomies, is_object_in_term

  # Determine if the given object type is associated with the given taxonomy.
  #
  # @param [string] object_type Object type string.
  # @param [string] taxonomy    Single taxonomy name.
  # @return [bool] True if object is associated with the taxonomy, otherwise false.
  def is_object_in_taxonomy(object_type, taxonomy)
    taxonomies = get_object_taxonomies(object_type)
    return false if taxonomies.blank?
    taxonomies.include? taxonomy
  end

  # TODO get_ancestors, wp_get_term_taxonomy_parent_id, wp_check_term_hierarchy_for_loops, is_taxonomy_viewable, wp_cache_set_terms_last_changed, wp_check_term_meta_support_prefilter


end