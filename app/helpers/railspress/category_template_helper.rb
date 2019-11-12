=begin
 * Taxonomy API: Core category-specific template tags
 *
 * file wp-includes\category-template.php
=end
module Railspress::CategoryTemplateHelper

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
      links << '<a href="' + esc_url(link) + '" rel="tag" class="badge badge-secondary">' + term.name + '</a>' # TODO make a filter for the class
    end

    # Filters the term links for a given taxonomy.
    #
    # The dynamic portion of the filter name, `$taxonomy`, refers to the taxonomy slug.
    term_links = apply_filters("term_links-#{taxonomy}", links)

    before + term_links.join(sep) + after
  end

end