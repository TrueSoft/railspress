=begin
 * Post format functions.
 *
 * file wp-includes\post-formats.php
=end
module Railspress::PostFormatsHelper
  # Retrieve the format slug for a post
  #
  # @param [int|object|null] post Post ID or post object. Optional, default is the current post from the loop.
  # @return string|false The format if successful. False otherwise.
  def get_post_format(post = nil)
    post = get_post(post)

    return false if post.blank?
    return false unless post_type_supports(post.post_type, 'post-formats')

    _format = get_the_terms(post.ID, 'post_format')

    return false if _format.blank?

    format = _format # ? reset(_format)

    format.slug.gsub('post-format-', '')
  end

  # TODO has_post_format, set_post_format, get_post_format_strings, get_post_format_slugs, get_post_format_string, get_post_format_link, _post_format_request, _post_format_link, _post_format_get_term, _post_format_get_terms, _post_format_wp_get_object_terms
end