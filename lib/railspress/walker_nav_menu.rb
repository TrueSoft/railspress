require_relative 'walker'
class Railspress::WalkerNavMenu < ::Railspress::Walker

  include Railspress::Functions
  include Railspress::Plugin
  include Railspress::FormattingHelper
  include Railspress::OptionsHelper
  include Railspress::KsesHelper

  def initialize
    @tree_type = ['post_type', 'taxonomy', 'custom']
    @db_fields = {parent: :menu_item_parent, id: :db_id}
  end

  # Starts the list before the elements are added.
  #
  # @param [string]   output Used to append additional content (passed by reference).
  # @param [int]      depth  Depth of menu item. Used for padding.
  # @param [stdClass] args   An object of wp_nav_menu() arguments.
  def start_lvl(output, depth = 0, args = {})
    t, n = 'discard' == args[:item_spacing] ? ['', ''] : ["\t", "\n"]

    indent = t * depth

    # Default class.
    classes = ['sub-menu']

    # Filters the CSS class(es) applied to a menu list element.
    class_names = apply_filters('nav_menu_submenu_css_class', classes, args, depth).join(' ')
    class_names = class_names ? ' class="' + esc_attr(class_names) + '"' : ''

    output << "#{n}#{indent}<ul#{class_names}>#{n}"
  end

  # Ends the list of after the elements are added.
  #
  # @param [string]   output Used to append additional content (passed by reference).
  # @param [int]      depth  Depth of menu item. Used for padding.
  # @param [stdClass] args   An object of wp_nav_menu() arguments.
  def end_lvl(output, depth = 0, args = {})
    t, n = 'discard' == args[:item_spacing] ? ['', ''] : ["\t", "\n"]
    indent = t * depth
    output << "#{indent}</ul>#{n}"
  end

  # Starts the element output.
  #
  # @param [string]   output Used to append additional content (passed by reference).
  # @param [WP_Post]  item   Menu item data object.
  # @param [int]      depth  Depth of menu item. Used for padding.
  # @param [stdClass] args   An object of wp_nav_menu() arguments.
  # @param [int]      id     Current item ID.
  def start_el(output, item, depth = 0, args = {}, id = 0)
    t, n = 'discard' == args[:item_spacing] ? ['', ''] : ["\t", "\n"]
    indent = t * depth

    classes = item.classes.blank? ? [] : item.classes
    classes << 'menu-item-' + item.id.to_s

    # Filters the arguments for a single nav menu item.
    args = apply_filters('nav_menu_item_args', args, item, depth)

    # Filters the CSS classes applied to a menu item's list item element.
    #
    # @param string[] $classes Array of the CSS classes that are applied to the menu item's `<li>` element.
    # @param WP_Post  $item    The current menu item.
    # @param stdClass $args    An object of wp_nav_menu() arguments.
    # @param int      $depth   Depth of menu item. Used for padding.
    class_names = apply_filters('nav_menu_css_class', classes.reject(&:blank?), item, args, depth).join(' ')
    class_names = class_names ? ' class="' + esc_attr(class_names) + '"' : ''

    # Filters the ID applied to a menu item's list item element.
    id = apply_filters('nav_menu_item_id', 'menu-item-' + item.id.to_s, item, args, depth)
    id = id ? ' id="' + esc_attr(id) + '"' : ''

    output << indent + '<li' + id + class_names + '>'

    atts = {}
    atts['title'] = item.attr_title || ''
    atts['target'] = item.target || ''
    if '_blank' == item.target && item.xfn.blank?
      atts['rel'] = 'noopener noreferrer'
    else
      atts['rel'] = item.xfn
    end
    atts['href'] = item.url || ''
    atts['aria-current'] = item.current ? 'page' : ''

    # Filters the HTML attributes applied to a menu item's anchor element.
    #
    # @param array $atts {
    #     The HTML attributes applied to the menu item's `<a>` element, empty strings are ignored.
    #
    #     @type string $title        Title attribute.
    #     @type string $target       Target attribute.
    #     @type string $rel          The rel attribute.
    #     @type string $href         The href attribute.
    #     @type string $aria_current The aria-current attribute.
    # }
    # @param WP_Post  $item  The current menu item.
    # @param stdClass $args  An object of wp_nav_menu() arguments.
    # @param int      $depth Depth of menu item. Used for padding.
    atts = apply_filters('nav_menu_link_attributes', atts, item, args, depth)

    attributes = ''
    atts.each_pair do |attr, value|
      unless value.blank?
        value = ('href' == attr.to_s) ? esc_url(value) : esc_attr(value)
        attributes += ' ' + attr + '="' + value + '"'
      end
    end

    # This filter is documented in wp-includes/post-template.php
    title = apply_filters('the_title', item.title, item.id)

    # Filters a menu item's title.
    #
    # @param string   $title The menu item's title.
    # @param WP_Post  $item  The current menu item.
    # @param stdClass $args  An object of wp_nav_menu() arguments.
    # @param int      $depth Depth of menu item. Used for padding.
    title = apply_filters('nav_menu_item_title', title, item, args, depth)

    item_output = args[:before]
    item_output += '<a' + attributes + '>'
    item_output += args[:link_before] + title + args[:link_after]
    item_output += '</a>'
    item_output += args[:after]

    # Filters a menu item's starting output.
    #
    # The menu item's starting output only includes `$args->before`, the opening `<a>`,
    # the menu item's title, the closing `</a>`, and `$args->after`. Currently, there is
    # no filter for modifying the opening and closing `<li>` for a menu item.
    output << apply_filters('walker_nav_menu_start_el', item_output, item, depth, args)
  end

  # Ends the element output, if needed.
  #
  # @param [string]   output Used to append additional content (passed by reference).
  # @param [WP_Post]  item   Page data object. Not used.
  # @param [int]      depth  Depth of page. Not Used.
  # @param [stdClass] args   An object of wp_nav_menu() arguments.
  def end_el(output, item, depth = 0, args = {})
    if 'discard' == args[:item_spacing]
      t, n = '', ''
    else
      t, n = "\t", "\n"
    end
    output << "</li>#{n}"
  end
end
