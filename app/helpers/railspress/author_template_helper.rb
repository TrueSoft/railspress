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

  # TODO the_author get_the_modified_author the_modified_author

  # Retrieves the requested data of the author of the current post.
  #
  # Valid values for the `$field` parameter include:
  #
  # - admin_color
  # - aim
  # - comment_shortcuts
  # - description
  # - display_name
  # - first_name
  # - ID
  # - jabber
  # - last_name
  # - nickname
  # - plugins_last_view
  # - plugins_per_page
  # - rich_editing
  # - syntax_highlighting
  # - user_activation_key
  # - user_description
  # - user_email
  # - user_firstname
  # - user_lastname
  # - user_level
  # - user_login
  # - user_nicename
  # - user_pass
  # - user_registered
  # - user_status
  # - user_url
  # - yim
  #
  # @global object $authordata The current author's DB object.
  #
  # @param [string]    field   Optional. The user field to retrieve. Default empty.
  # @param [int|false] user_id Optional. User ID.
  # @return [string] The author's field from the current author's DB object, otherwise an empty string.
  def get_the_author_meta( field = '', user_id = false )
    original_user_id = user_id

    if user_id == false
      # global $authordata;
      user_id = isset( authordata.id ) ? authordata.id : 0
    else
      authordata = Railspress::User.find(user_id) # get_userdata( user_id )
    end

    if %w(login pass nicename email url registered activation_key status).include?( field )
      field = 'user_' + field
    end

    value = authordata[field.to_sym] || ''

    # Filters the value of the requested user metadata.
    #
    # The filter name is dynamic and depends on the $field parameter of the function.
    #
    # @param string    value            The value of the metadata.
    # @param int       user_id          The user ID for the value.
    # @param int|false original_user_id The original user ID, as passed to the function.
    apply_filters( "get_the_author_#{field}", value, user_id, original_user_id )
  end

  # TODO the_author_meta get_the_author_link the_author_link get_the_author_posts the_author_posts get_the_author_posts_link the_author_posts_link

  # Retrieve the URL to the author page for the user with the ID provided.
  #
  # @global WP_Rewrite $wp_rewrite WordPress rewrite component.
  #
  # @param [int]    author_id       Author ID.
  # @param [string] author_nicename Optional. The author's nicename (slug). Default empty.
  # @return [string] The URL to the author's page.
  def get_author_posts_url(author_id, author_nicename = '')
    # global $wp_rewrite;

    auth_ID = author_id.to_i
    link = Railspress.GLOBAL.wp_rewrite.get_author_permastruct

    if link.blank?
      file = home_url('/')
      link = file + '?author=' + auth_ID
    else
      if '' == author_nicename
        user = Railspress::User.find(author_id) # get_userdata( author_id )
        author_nicename = user.user_nicename unless user.user_nicename.blank?
      end
      link = link.gsub(/%author%/, author_nicename)
      link = home_url(user_trailingslashit(link))
    end

    unless Railspress.links_to_wp
      link = wp_url_to_relative_url(link)
    end

    # Filters the URL to the author's page.
    #
    # @param string $link            The URL to the author's page.
    # @param int    $author_id       The author's id.
    # @param string $author_nicename The author's nice name.
    apply_filters('author_link', link, author_id, author_nicename)
  end

  # TODO wp_list_authors is_multi_author __clear_multi_author_cache

end