=begin
 * Taxonomy API: Core category-specific template tags
 *
 * file wp-includes\category-template.php
=end
module Railspress::CategoryTemplateHelper

  # Retrieve category link URL.
  #
  # @param [Int|object] category Category ID or object.
  # @return [string] Link on success, empty string if category does not exist.
  def get_category_link(category)
    # if ( ! is_object( category ) )
    #   category = (int) category
    # end

    category = get_term_link( category )
    return '' if category.is_a? Railspress::WP_Error # is_wp_error

    return category
  end

  # Retrieve category parents with separator.
  #
  # @param [int] 	id Category ID.
  # @param [bool] 	link Optional, default is false. Whether to format with link.
  # @param [string] 	separator Optional, default is '/'. How to separate categories.
  # @param [bool] 	nicename Optional, default is false. Whether to use nice name for display.
  # @param [array] 	deprecated Not used.
  # @return string|WP_Error A list of category parents on success, WP_Error on failure.
  def get_category_parents(id, link = false, separator = '/', nicename = false, deprecated = [])

    format = nicename ? 'slug' : 'name'

    args = {separator: separator, link: link, format: format}

    get_term_parents_list( id, 'category', args )
  end

  # Retrieve post categories.
  #
  # This tag may be used outside The Loop by passing a post id as the parameter.
  #
  # Note: This function only returns results from the default "category" taxonomy.
  # For custom taxonomies use get_the_terms().
  #
  # @param [int] id Optional, default to current post ID. The post ID.
  # @return WP_Term[] Array of WP_Term objects, one for each category assigned to the post.
  def get_the_category( id = false )
    categories = get_the_terms( id, 'category' )
    if !categories || categories.is_a?(Railspress::WP_Error)
      categories = {}
    end

    categories = categories.values.to_a if categories.is_a?(Hash)

    # foreach ( array_keys( categories ) as $key ) {
    # 	_make_cat_compat( categories[ key ] );
    # }

    # Filters the array of categories to return for a post.
    apply_filters( 'get_the_categories', categories, id )
  end

  # get_the_category_by_ID

  def get_the_category_list(separator = '', parents = '', post_id = false)
    return apply_filters('the_category', '', separator, parents) unless is_object_in_taxonomy(post_id.post_type, 'category')
    # Filters the categories before building the category list.
    categories = apply_filters('the_category_list', get_the_category(post_id), post_id)
    return apply_filters('the_category', t('railspress.category.uncategorized'), separator, parents) if categories.blank?

    rel = true || using_permalinks ? 'rel="category tag"' : 'rel="category"'

    thelist = ''
    if '' == separator
      thelist += '<ul class="post-categories">'
      categories.each do |category|
        case parents.downcase
        when 'multiple'
          if category.parent
            thelist += get_category_parents( category.parent, true, separator )
          end
          thelist += '<a href="' + esc_url( get_category_link( category.term_id ) ) + '" ' + rel + '>' + category.name + '</a></li>'
        when 'single'
          thelist += '<a href="' + esc_url(get_category_link(category.term_id)) + '"  ' + rel + '>'
          if category.parent
            thelist += get_category_parents(category.parent, false, separator)
          end
          thelist += category.name + '</a></li>'
        else
          thelist += '<a href="' + esc_url(get_category_link(category.term_id)) + '" ' + rel + '>' + category.name + '</a></li>'
        end
      end
      thelist += '</ul>'
    else
      i = 0
      categories.each do |category|
        thelist += separator if 0 < i
        case parents.downcase
        when 'multiple'
          if category.parent
            thelist += get_category_parents(category.parent, true, separator)
          end
          thelist += '<a href="' + esc_url(get_category_link(category.term_id)) + '" ' + rel + '>' + category.name + '</a>'
        when 'single'
          thelist += '<a href="' + esc_url(get_category_link(category.term_id)) + '" ' + rel + '>'
          if category.parent
            thelist += get_category_parents(category.parent, false, separator)
          end
          thelist += category.name + "</a>"
        else
          thelist += '<a href="' + esc_url(get_category_link(category.term_id)) + '" ' + rel + '>' + category.name + '</a></li>'
        end
        i += 1
      end
    end
    # Filters the category or list of categories.
    apply_filters('the_category', thelist, separator, parents)
  end

  # Retrieve the tags for a post.
  #
  # @param [int] id Post ID.
  # @return [array|false|WP_Error] Array of tag objects on success, false on failure.
  def get_the_tags(id = 0)
    # Filters the array of tags for the given post.
    apply_filters('get_the_tags', get_the_terms(id, 'post_tag'))
  end

  # Retrieve the tags for a post formatted as a string.
  #
  # @param [string] before Optional. Before tags.
  # @param [string] sep Optional. Between tags.
  # @param [string] after Optional. After tags.
  # @param [int] id Optional. Post ID. Defaults to the current post.
  # @return string|false|WP_Error A list of tags on success, false if there are no terms, WP_Error on failure.
  def get_the_tag_list(before = '', sep = '', after = '', id = 0)
    # Filters the tags list for a given post.
    apply_filters('the_tags', get_the_term_list(id, 'post_tag', before, sep, after), before, sep, after, id)
  end

  # Retrieve the terms of the taxonomy that are attached to the post.
  #
  # @since 2.5.0
  #
  # @param [int|WP_Post] post     Post ID or object.
  # @param [string]      taxonomy Taxonomy name.
  # @return [WP_Term[]|false|WP_Error] Array of WP_Term objects on success, false if there are no terms
  #                                    or the post does not exist, WP_Error on failure.
  def get_the_terms(post, taxonomy)
    post = get_post(post)

    return false if post.nil?

    terms = false # TODO get_object_term_cache(post.id, taxonomy)
    if terms == false
      terms = wp_get_object_terms(post.id, taxonomy)
      unless terms.is_a? Railspress::WP_Error
        # term_ids = wp_list_pluck(terms, 'term_id')
        # TODO wp_cache_add(post.id, term_ids, taxonomy + '_relationships')
      end
    end

    # Filters the list of terms attached to the given post.
    terms = apply_filters('get_the_terms', terms, post.id, taxonomy)

    return false if terms.blank?

    terms
  end

  # Retrieve a post's terms as a list with specified format.
  #
  # @param [int] id Post ID.
  # @param [string] taxonomy Taxonomy name.
  # @param [string] before Optional. Before list.
  # @param [string] sep Optional. Separate items using this.
  # @param [string] after Optional. After list.
  # @return string|false|WP_Error A list of terms on success, false if there are no terms, WP_Error on failure.
  def get_the_term_list(id, taxonomy, before = '', sep = '', after = '')
    terms = get_the_terms(id, taxonomy)

    return terms if terms.is_a? Railspress::WP_Error

    return false if terms.blank?

    links = []

    terms.each do |term|
      link = get_term_link(term, taxonomy)
      return link if link.is_a? Railspress::WP_Error
      links << '<a href="' + esc_url(link) + '" rel="tag" class="badge bg-secondary text-light text-decoration-none">' + term.name + '</a>' # TODO make a filter for the class
    end

    # Filters the term links for a given taxonomy.
    #
    # The dynamic portion of the filter name, `$taxonomy`, refers to the taxonomy slug.
    term_links = apply_filters("term_links-#{taxonomy}", links)

    before + term_links.join(sep) + after
  end

  # Retrieve term parents with separator.
  #
  # @param [int]     term_id  Term ID.
  # @param [string]  taxonomy Taxonomy name.
  # @param [string|array] args {
  #     Array of optional arguments.
  #
  #     @type string :format    Use term names or slugs for display. Accepts 'name' or 'slug'.
  #                             Default 'name'.
  #     @type string :separator Separator for between the terms. Default '/'.
  #     @type bool   :link      Whether to format as a link. Default true.
  #     @type bool   :inclusive Include the term to get the parents for. Default true.
  # }
  # @return [string|WP_Error] A list of term parents on success, WP_Error or empty string on failure.
  def get_term_parents_list( term_id, taxonomy, args = {} )
    list = ''
    term = get_term( term_id, taxonomy )

    return term if term.is_a?(Railspress::WP_Error)

    return list unless term

    term_id = term.term_id

    defaults = {
        format: 'name',
        separator: '/',
        link: true,
        inclusive: true,
    }

    args = wp_parse_args(args, defaults)

    %i(link inclusive).each do |bool|
      args[bool] = wp_validate_boolean(args[bool])
    end

    parents = get_ancestors(term_id, taxonomy, 'taxonomy')

    parents.unshift(term_id) if args[:inclusive]

    parents.reverse.each do |term_id|
      parent = get_term(term_id, taxonomy )
      name   = ('slug' == args[:format] ) ? parent.slug : parent.name

      if args[:link]
        list += '<a href="' + esc_url( get_term_link( parent.term_id, taxonomy)) + '">' + name + '</a>' + args[:separator]
      else
        list += name + args[:separator]
      end
    end

    list
  end

end