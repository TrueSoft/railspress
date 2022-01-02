  # WP_Bootstrap_Navwalker
  # A custom WordPress nav walker class to implement the Bootstrap 4 navigation style
  # in a custom theme using the WordPress built in menu manager.
  #
  # @see https://github.com/wp-bootstrap/wp-bootstrap-navwalker
  require_relative 'walker_nav_menu'
  class Railspress::BootstrapNavwalker < ::Railspress::WalkerNavMenu

    include Railspress::FormattingHelper

    # Starts the list before the elements are added.
    def start_lvl(output, depth = 0, args = {})
      t, n = 'discard' == args[:item_spacing] ? ['', ''] : ["\t", "\n"]

      indent = t * depth

      # Default class to add to the file
      classes = ['dropdown-menu']

      # Filters the CSS class(es) applied to a menu list element.
      class_names = apply_filters('nav_menu_submenu_css_class', classes, args, depth).join(' ')
      class_names = class_names ? ' class="' + Railspress::FormattingHelper.esc_attr(class_names) + '"' : ''

      # The `.dropdown-menu` container needs to have a labelledby
      # attribute which points to it's trigger link.
      #
      # Form a string for the labelledby attribute from the the latest
      # link with an id that was added to the $output.
      labelledby = ''
      # find all links with an id in the output.
      matches = output.match /(<a.*?id="|')(.*?)"|'.*?>/im
      # with pointer at end of array check if we got an ID match.
      unless matches[2].blank?
        # build a string to use as aria-labelledby.
        labelledby = 'aria-labelledby="' + matches[2] + '"'
      end
      output << "#{n}#{indent}<ul#{class_names} #{labelledby} role=\"menu\">#{n}"
    end

    # Starts the element output.
    def start_el(output, item, depth = 0, args = {}, id = 0)
      t, n = 'discard' == args[:item_spacing] ? ['', ''] : ["\t", "\n"]
      indent = t * depth

      classes = item.classes.blank? ? [] : item.classes
      classes << 'menu-item-' + item.id.to_s

      # Initialize some holder variables to store specially handled item wrappers and icons.
      linkmod_classes = []
      icon_classes    = []

      # Get an updated $classes array without linkmod or icon classes.
      #
      # NOTE: linkmod and icon class arrays are passed by reference and
      # are maybe modified before being used later in this function.
      classes = separate_linkmods_and_icons_from_classes(classes, linkmod_classes, icon_classes, depth )

      # Join any icon classes plucked from $classes into a string.
      icon_class_string = icon_classes.join(' ')

      # Filters the arguments for a single nav menu item.
      args = apply_filters( 'nav_menu_item_args', args, item, depth )

      # Add .dropdown or .active classes where they are needed.
      classes << 'dropdown' if args[:has_children]

      if classes.include?('current-menu-item') || classes.include?( 'current-menu-parent')
        classes << 'active'
      end

      # Add some additional default classes to the item.
      classes << 'nav-item'

      # Allow filtering the classes.
      class_names = apply_filters( 'nav_menu_css_class', classes.reject(&:blank?), item, args, depth ).join(' ')
      class_names = class_names ? ' class="' + Railspress::FormattingHelper.esc_attr(class_names) + '"' : ''

      # Filters the ID applied to a menu item's list item element.
      id = apply_filters('nav_menu_item_id', 'menu-item-' + item.id.to_s, item, args, depth)
      id = id ? ' id="' + Railspress::FormattingHelper.esc_attr(id) + '"' : ''

      output << indent + '<li itemscope="itemscope" itemtype="https://www.schema.org/SiteNavigationElement"' + id + class_names + '>'

      atts = {}
      atts['title'] = item.attr_title || ''
      atts['target'] = item.target || ''
      if '_blank' == item.target && item.xfn.blank?
        atts['rel'] = 'noopener noreferrer'
      else
        atts['rel'] = item.xfn
      end
      # If item has_children add atts to <a>.
      if args[:has_children] && 0 == depth && args[:depth].to_i > 1
        atts['href']          = '#'
        atts['data-toggle']   = 'dropdown'
        atts['data-bs-toggle'] = 'dropdown'
        atts['aria-haspopup'] = 'true'
        atts['aria-expanded'] = 'false'
        atts['class']         = 'dropdown-toggle nav-link'
        atts['id']            = 'menu-item-dropdown-' + item.id.to_s
      else
        atts['href'] = item.url || '#'
        # Items in dropdowns use .dropdown-item instead of .nav-link.
        if depth > 0
          atts['class'] = 'dropdown-item'
        else
          atts['class'] = 'nav-link'
        end
      end

      # update atts of this item based on any custom linkmod classes.
      atts = update_atts_for_linkmod_type( atts, linkmod_classes )
      # Allow filtering of the $atts array before using it.
      atts = apply_filters( 'nav_menu_link_attributes', atts, item, args, depth )

      attributes = ''
      atts.each_pair do |attr, value|
        unless value.blank?
          value = ('href' == attr.to_s) ? esc_url(value) : Railspress::FormattingHelper.esc_attr(value)
          attributes += ' ' + attr + '="' + value + '"'
        end
      end

      # Set a typeflag to easily test if this is a linkmod or not.
      linkmod_type = get_linkmod_type( linkmod_classes )

      # START appending the internal item contents to the output.
      item_output = args[:before]
      # This is the start of the internal nav item. Depending on what
      # kind of linkmod we have we may need different wrapper elements.
      if !linkmod_type.blank?
        # is linkmod, output the required element opener.
        item_output += linkmod_element_open( linkmod_type, attributes )
      else
        # With no link mod type set this must be a standard <a> tag.
        item_output += '<a' + attributes + '>'
      end

      # Initiate empty icon var, then if we have a string containing any
      # icon classes form the icon markup with an <i> element. This is
      # output inside of the item before the $title (the link text).
      icon_html = ''
      unless icon_class_string.blank?
        # append an <i> with the icon classes to what is output before links.
        icon_html = '<i class="' + Railspress::FormattingHelper.esc_attr( icon_class_string ) + '" aria-hidden="true"></i> '
      end

      # This filter is documented in wp-includes/post-template.php
      title = apply_filters('the_title', item.title, item.id)

      # Filters a menu item's title.
      title = apply_filters('nav_menu_item_title', title, item, args, depth)
      # If the .sr-only class was set apply to the nav items text only.
      if linkmod_classes.include?('sr-only')
        title = wrap_for_screen_reader(title)
        linkmod_classes -= ['sr-only']
      end

      # Put the item contents into $output.
      item_output += args[:link_before] + icon_html + title + args[:link_after]
      # This is the end of the internal nav item. We need to close the
      # correct element depending on the type of link or link mod.
      if !linkmod_type.blank?
        # is linkmod, output the required element opener.
        item_output += linkmod_element_close(linkmod_type )
      else
        # With no link mod type set this must be a standard <a> tag.
        item_output += '</a>'
      end

      item_output += args[:after]

      # END appending the internal item contents to the output.
      output << apply_filters('walker_nav_menu_start_el', item_output, item, depth, args)
    end

    # Traverse elements to create list from elements.
    #
    # Display one element if the element doesn't have any children otherwise,
    # display the element and its children. Will only traverse up to the max
    # depth and no ignore elements under that depth. It is possible to set the
    # max depth to include all depths, see walk() method.
    #
    # This method should not be called directly, use the walk() method instead.
    #
    # @see Walker::start_lvl()
    #
    # @param [object] element           Data object.
    # @param [array]  children_elements List of elements to continue traversing (passed by reference).
    # @param [int]    max_depth         Max depth to traverse.
    # @param [int]    depth             Depth of current element.
    # @param [array]  args              An array of arguments.
    # @param [string] output            Used to append additional content (passed by reference).
    def display_element(element, children_elements, max_depth, depth, args, output)
      return if element.blank?
      id_field = @db_fields[:id]
      id = element.send(id_field)
      # Display this element.

      @has_children = !children_elements[id].blank?
      if args[0].is_a? Hash
        args[0][:has_children] = @has_children
      end

      super(element, children_elements, max_depth, depth, args, output )
    end

    # Menu Fallback
    # =============
    # If this function is assigned to the wp_nav_menu's fallback_cb variable
    # and a menu has not been assigned to the theme location in the WordPress
    # menu manager the function with display nothing to a non-logged in user,
    # and will add a link to the WordPress menu manager if logged in as an admin.
    #
    # @param array $args passed from the wp_nav_menu function.
    def self.fallback(args)
      if false && current_user_can( 'edit_theme_options' )

        # Get Arguments.
        container       = args[:container]
        container_id    = args[:container_id]
        container_class = args[:container_class]
        menu_class      = args[:menu_class]
        menu_id         = args[:menu_id]

        # initialize var to store fallback html.
        fallback_output = ''

        if container
          fallback_output << '<' + esc_attr( container )
          fallback_output << ' id="' + esc_attr( container_id ) + '"'  if  container_id
          fallback_output << ' class="' + esc_attr( container_class ) + '"' if  container_class
          fallback_output << '>'
        end
        fallback_output << '<ul'
        fallback_output << ' id="' + esc_attr( menu_id ) + '"' if menu_id
        fallback_output << ' class="' + esc_attr( menu_class ) + '"' if menu_class
        fallback_output << '>'
        fallback_output << '<li><a href="' + esc_url( admin_url( 'nav-menus.php' ) ) + '" title="' + esc_attr__( 'Add a menu' ) + '">' + esc_html__( 'Add a menu' ) + '</a></li>'
        fallback_output << '</ul>'

        fallback_output << '</' + esc_attr(container) + '>' if container

        # if $args has 'echo' key and it's true echo, otherwise return.
        if args[:echo]
          return fallback_output # WPCS: XSS OK.
        else
          return fallback_output
        end
      end
    end

    private

    # Find any custom linkmod or icon classes and store in their holder
    # arrays then remove them from the main classes array.
    #
    # Supported linkmods: .disabled, .dropdown-header, .dropdown-divider, .sr-only
    # Supported iconsets: Font Awesome 4/5, Glypicons
    #
    # NOTE: This accepts the linkmod and icon arrays by reference.
    #
    # @param [array]   classes         an array of classes currently assigned to the item.
    # @param [array]   linkmod_classes an array to hold linkmod classes.
    # @param [array]   icon_classes    an array to hold icon classes.
    # @param [integer] depth           an integer holding current depth level.
    #
    # @return [array]  classes         a maybe modified array of classnames.
    def separate_linkmods_and_icons_from_classes(classes, linkmod_classes, icon_classes, depth)
      new_classes = []
      # Loop through $classes array to find linkmod or icon classes.
      classes.each do |cls|
        # If any special classes are found, store the class in it's
        # holder array and and unset the item from $classes.
        if cls =~ /^disabled|^sr-only/i
          # Test for .disabled or .sr-only classes.
          linkmod_classes << cls
        elsif cls =~ /^dropdown-header|^dropdown-divider|^dropdown-item-text/i && depth > 0
          # Test for .dropdown-header or .dropdown-divider and a depth greater than 0 - IE inside a dropdown.
          linkmod_classes << cls
        elsif cls =~ /^fa-(\S*)?|^fa(s|r|l|b)?(\s?)?$/i
          # Font Awesome.
          icon_classes << cls
        elsif cls =~ /^glyphicon-(\S*)?|^glyphicon(\s?)$/i
          # Glyphicons.
          icon_classes << cls
        else
          new_classes << cls
        end
      end
      new_classes
    end

    # Return a string containing a linkmod type and update atts array
    # accordingly depending on the decided.
    #
    # @param [array] linkmod_classes array of any link modifier classes.
    #
    # @return [string]               empty for default, a linkmod type string otherwise.
    def get_linkmod_type(linkmod_classes = [] )
      linkmod_type = ''
      # Loop through array of linkmod classes to handle their $atts.
      unless linkmod_classes.blank?
        linkmod_classes.each do |link_class|
          unless link_class.blank?
            # check for special class types and set a flag for them.
            if  'dropdown-header' == link_class
              linkmod_type = 'dropdown-header'
            elsif  'dropdown-divider' == link_class
              linkmod_type = 'dropdown-divider'
            elsif  'dropdown-item-text' == link_class
              linkmod_type = 'dropdown-item-text'
            end
          end
        end
      end
      linkmod_type
    end

    # Update the attributes of a nav item depending on the limkmod classes.
    #
    # @param [array] atts            array of atts for the current link in nav item.
    # @param [array] linkmod_classes an array of classes that modify link or nav item behaviors or displays.
    #
    # @return [array]                maybe updated array of attributes for item.
    def update_atts_for_linkmod_type(atts = [], linkmod_classes = [])
      unless linkmod_classes.blank?
        linkmod_classes.each do |link_class|
          unless link_class.blank?
            # update $atts with a space and the extra classname...
            # so long as it's not a sr-only class.
            if 'sr-only' != link_class
              atts['class'] ||= ''
              atts['class'] += ' ' + Railspress::FormattingHelper.esc_attr( link_class )
            end
            # check for special class types we need additional handling for.
            if 'disabled' == link_class
              # Convert link to '#' and unset open targets.
              atts['href'] = '#'
              atts.delete('target')
            elsif  'dropdown-header' == link_class || 'dropdown-divider' == link_class || 'dropdown-item-text' == link_class
              # Store a type flag and unset href and target.
              atts.delete('href')
              atts.delete('target')
            end
          end
        end
      end
      atts
    end

    # Wraps the passed text in a screen reader only class.
    #
    # @param [string] text the string of text to be wrapped in a screen reader class.
    # @return [string]     the string wrapped in a span with the class.
    def wrap_for_screen_reader( text = '' )
      text = '<span class="sr-only">' + text + '</span>' unless text.blank?
      text
    end

    # Returns the correct opening element and attributes for a linkmod.
    #
    # @param [string] linkmod_type a sting containing a linkmod type flag.
    # @param [string] attributes   a string of attributes to add to the element.
    #
    # @return [string]             a string with the opening tag for the element with attributes added.
    def linkmod_element_open( linkmod_type, attributes = '' )
      output = ''
      if 'dropdown-item-text' == linkmod_type
        output << '<span class="dropdown-item-text"' + attributes + '>'
      elsif  'dropdown-header' == linkmod_type
        # For a header use a span with the .h6 class instead of a real
        # header tag so that it doesn't confuse screen readers.
        output << '<span class="dropdown-header h6"' + attributes + '>'
      elsif  'dropdown-divider' == linkmod_type
        # this is a divider.
        output << '<div class="dropdown-divider"' + attributes + '>'
      end
      output
    end

    # Return the correct closing tag for the linkmod element.
    #
    # @param [string] linkmod_type a string containing a special linkmod type.
    #
    # @return [string]             a string with the closing tag for this linkmod type.
    def linkmod_element_close(linkmod_type)
      output = ''
      if 'dropdown-header' == linkmod_type || 'dropdown-item-text' == linkmod_type
        # For a header use a span with the .h6 class instead of a real
        # header tag so that it doesn't confuse screen readers.
        output << '</span>'
      elsif 'dropdown-divider' == linkmod_type
        # this is a divider.
        output << '</div>'
      end
      output
    end
  end