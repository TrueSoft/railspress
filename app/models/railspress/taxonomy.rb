require 'railspress/plugin'
require 'railspress/load'

class Railspress::Taxonomy < Railspress::ApplicationRecord
    self.table_name = self.prefix_table_name('term_taxonomy')
    self.primary_key = :term_taxonomy_id
    self.inheritance_column = 'taxonomy'

    include Railspress::Load
    include Railspress::FormattingHelper
    include Railspress::TaxonomyLib

    def self.find_sti_class type_name
      case type_name
      when 'post_type', 'post_format'
        Railspress::Taxonomy
      else
        "railspress/#{type_name}".camelize.constantize
      end
    rescue NameError
      Railspress::CustomTaxonomy
    end

    def self.sti_name
      name.underscore.split("/").last
    end

    before_create :set_defaults

    has_many :relationships, foreign_key: "term_taxonomy_id"
    has_many :posts, through: :relationships
    has_many :categories, through: :relationships
    has_many :tags, through: :relationships

    has_one :parent_node,
            class_name: Railspress::Taxonomy.name,
            primary_key: :parent,
            foreign_key: :term_taxonomy_id

    has_one :term, foreign_key: :term_id, primary_key: :term_id

    scope :for_cloud, -> { includes(:term).order(count: :desc).limit(40) }

    delegate :name, to: :term, allow_nil: true
    delegate :slug, to: :term, allow_nil: true

    attr_accessor :labels
    attr_accessor :label
    attr_accessor :rewrite
    attr_accessor :query_var
    attr_accessor :object_type
    attr_accessor :filter_str # or delegate to term's filter_str

    def initialize(attributes = nil)
      super(attributes)
      @name = attributes[:taxonomy]
    end

    def set_defaults
      self.description = '' unless self.description_changed?
    end

    # Sets taxonomy properties.
    #
    # @param [array|string] object_type Name of the object type for the taxonomy object.
    # @param [array|string] args        Array or query string of arguments for registering a taxonomy.
    def set_props(object_type, args)
      args = Railspress::Functions.wp_parse_args args

      # Filters the arguments for registering a taxonomy.
      args = Railspress::Plugin.apply_filters('register_taxonomy_args', args, @name, object_type)

      # Args prefixed with an underscore are reserved for internal use.
      defaults = {
          'labels' => {},
          'description'           => '',
          'public'                => true,
          'publicly_queryable'    => nil,
          'hierarchical'          => false,
          'show_ui'               => nil,
          'show_in_menu'          => nil,
          'show_in_nav_menus'     => nil,
          'show_tagcloud'         => nil,
          'show_in_quick_edit'    => nil,
          'show_admin_column'     => false,
          'meta_box_cb'           => nil,
          'meta_box_sanitize_cb'  => nil,
          'capabilities'          => {},
          'rewrite'               => true,
          'query_var'             => @name,
          'update_count_callback' => '',
          'show_in_rest'          => false,
          'rest_base'             => false,
          'rest_controller_class' => false,
          '_builtin' => false
      }

      args = defaults.merge args

      args['name'] = @name
      # If not set, default to the setting for public.
      args['publicly_queryable'] = args['public'] if args['publicly_queryable'].nil?

      if args['query_var'] != false && ( is_admin() || args['publicly_queryable'] != false )
        if args['query_var'] == true
          args['query_var'] = @name
        else
          args['query_var'] = sanitize_title_with_dashes( args['query_var'] )
        end
      else
        # Force query_var to false for non-public taxonomies.
        args['query_var'] = false
      end

      if args['rewrite'] != false && ( is_admin() ||  get_option('permalink_structure') != '' )
        args['rewrite'] = Railspress::Functions.wp_parse_args(
            args['rewrite'],
            {
                'with_front'   => true,
                'hierarchical' => false,
                'ep_mask'      => :EP_NONE
            }
        )

        args['rewrite']['slug'] = sanitize_title_with_dashes( @name ) if args['rewrite']['slug'].blank?
      end

      # If not set, default to the setting for public.
      args['show_ui'] = args['public'] if args['show_ui'].nil?

      # If not set, default to the setting for show_ui.
      args['show_in_menu'] = args['show_ui'] if args['show_in_menu'].nil? || !args['show_ui']

      # If not set, default to the setting for public.
      args['show_in_nav_menus'] = args['public'] if args['show_in_nav_menus'].nil?

      # If not set, default to the setting for show_ui.
      args['show_tagcloud'] = args['show_ui'] if args['show_tagcloud'].nil?

      # If not set, default to the setting for show_ui.
      args['show_in_quick_edit'] = args['show_ui'] if args['show_in_quick_edit'].nil?

      default_caps = {
          'manage_terms' => 'manage_categories',
          'edit_terms'   => 'manage_categories',
          'delete_terms' => 'manage_categories',
          'assign_terms' => 'edit_posts',
      }

      args['cap'] = default_caps.merge args['capabilities']
      args.except!('capabilities')

      args['object_type'] = [ object_type ]

      # If not set, use the default meta box
      if args['meta_box_cb'].nil?
        if args['hierarchical']
          args['meta_box_cb'] = 'post_categories_meta_box'
        else
          args['meta_box_cb'] = 'post_tags_meta_box'
        end
      end

      args['name'] = @name

      # Default meta box sanitization callback depends on the value of 'meta_box_cb'.
      if args['meta_box_sanitize_cb'].nil?
        args['meta_box_sanitize_cb'] = case args['meta_box_cb']
                                       when 'post_categories_meta_box'
                                         'taxonomy_meta_box_sanitize_cb_checkboxes'
                                       when 'post_tags_meta_box'
                                         'taxonomy_meta_box_sanitize_cb_input'
                                       else
                                         'taxonomy_meta_box_sanitize_cb_input'
                                       end
      end

      args.each_pair do |property_name, property_value|
        self.send(property_name + '=', property_value) if %w(label labels rewrite query_var object_type).include?(property_name) # TODO make attrs for all
      end

     @labels = get_taxonomy_labels( self )
     @label  = @labels['name']

    end

    # Adds the necessary rewrite rules for the taxonomy.
    def add_rewrite_rules
      # Non-publicly queryable taxonomies should not register query vars, except in the admin.
#      wp.add_query_var(@query_var) if (false != @query_var && wp)

      if false != @rewrite && (is_admin || '' != Railspress.GLOBAL.wp_rewrite.permalink_structure) # instead get_option('permalink_structure'))
        if @hierarchical && @rewrite['hierarchical']
          tag = '(.+?)'
        else
          tag = '([^/]+)'
        end
        Railspress.GLOBAL.wp_rewrite.add_rewrite_tag("%#{@name}%", tag, @query_var ? "#{@query_var}=" : "taxonomy=#{@name}&term=")
        Railspress.GLOBAL.wp_rewrite.add_permastruct(@name, "#{@rewrite['slug']}/%#{@name}%", @rewrite)
      end
    end

    def add_hooks
      # TODO implement from class class-wp-taxonomy.php
    end

    def breadcrumbs
      (parent_node ? [parent_node.breadcrumbs, self] : [self]).flatten
    end

    def title
      [name, description].compact.join(": ")
    end
end