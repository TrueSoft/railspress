=begin
 * Author Template functions for use in themes. 
 * 
 * These functions must be used within the WordPress Loop. 
 *
 * @link https://codex.wordpress.org/Author_Templates
 *
 * file wp-includes\author-template.php
=end
module Railspress::AuthorTemplateHelper

  # Retrieve the author of the current post.
  #
  # @global object $authordata The current author's DB object.
  #
  # @return [string|null] The author's display name. 
  def get_the_author(deprecated = '')
    # Filters the display name of the current post's author.
    #
    # @param string $authordata->display_name The author's display name.
    apply_filters( 'the_author', @authordata.nil? ? nil : @authordata.display_name) 
  end

  # TODO the_author get_the_modified_author the_modified_author get_the_author_meta the_author_meta get_the_author_link the_author_link get_the_author_posts the_author_posts get_the_author_posts_link the_author_posts_link get_author_posts_url wp_list_authors is_multi_author __clear_multi_author_cache

end