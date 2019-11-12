module Railspress
  # A custom nav walker class which displays the menu as div and links
  class WalkerListGroup < WalkerNavMenu
    def start_lvl(output, depth = 0, args = {})
      t, n = 'discard' == args[:item_spacing] ? ['', ''] : ["\t", "\n"]
      indent = t * depth
      output << "#{n}#{indent}"
    end

    def end_lvl(output, depth = 0, args = {})
      t, n = 'discard' == args[:item_spacing] ? ['', ''] : ["\t", "\n"]
      indent = t * depth
      output << "#{indent}#{n}"
    end

    # Starts the element output.
    def start_el(output, item, depth = 0, args = {}, id = 0)
      t, n = 'discard' == args[:item_spacing] ? ['', ''] : ["\t", "\n"]
      indent = t * depth

      classes = item.classes.blank? ? [] : item.classes
      classes << 'menu-item-' + item.id.to_s

      # Filters the arguments for a single nav menu item.
      args = apply_filters('nav_menu_item_args', args, item, depth)

      output << indent

      atts = {}
      # TODO id?
      # Filters the ID applied to a menu item's list item element.
      # id = apply_filters('nav_menu_item_id', 'menu-item-' + item.id.to_s, item, args, depth)
      # id = id ? ' id="' + esc_attr(id) + '"' : ''

      classes << 'list-group-item'
      classes << 'list-group-item-action'
      # Filters the CSS classes applied to a menu item's list item element.
      class_names = apply_filters('nav_menu_css_class', classes.reject(&:blank?), item, args, depth).join(' ')
      if class_names
        atts['class'] = esc_attr(class_names)
      end

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
      title = apply_filters('nav_menu_item_title', title, item, args, depth)

      item_output = args[:before]
      item_output += '<a' + attributes + '>'
      item_output += args[:link_before] + title + args[:link_after]
      item_output += '</a>'
      item_output += args[:after]

      # Filters a menu item's starting output.
      output << apply_filters('walker_nav_menu_start_el', item_output, item, depth, args)
    end

    def end_el(output, item, depth = 0, args = {})
      if 'discard' == args[:item_spacing]
        t, n = '', ''
      else
        t, n = "\t", "\n"
      end
      output << "#{n}"
    end

  end
end
