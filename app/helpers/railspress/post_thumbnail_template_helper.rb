=begin
 * WordPress Post Thumbnail Template Functions.
 *
 * Support for post thumbnails.
 *
 * file wp-includes\post-thumbnail-template.php
=end
module Railspress::PostThumbnailTemplateHelper

  # Determines whether a post has an image attached.
  def has_post_thumbnail(post = nil )
    thumbnail_id  = get_post_thumbnail_id( post )
    has_thumbnail = thumbnail_id =~ /\d+/

    # Filters whether a post has a post thumbnail.
    apply_filters('has_post_thumbnail', has_thumbnail, post, thumbnail_id)
  end

  # Retrieve post thumbnail ID.
  def get_post_thumbnail_id(post = nil)
    post = get_post(post)
    return '' if post.nil?
    get_post_meta(post.id, '_thumbnail_id', true )
  end

  # Retrieve the post thumbnail.
  #
  # When a theme adds 'post-thumbnail' support, a special 'post-thumbnail' image size is registered,
  # which differs from the 'thumbnail' image size managed via the Settings > Media screen.
  #
  # When using the_post_thumbnail() or related functions, the 'post-thumbnail' image
  # size is used by default, though a different size can be specified instead as needed.
  # @param size  Optional. Image size to use. Accepts any valid image size, or an array of width and
  #                            height values in pixels (in that order). Default 'post-thumbnail'.
  # @param attr Optional. Query string or array of attributes. Default empty.
  # @return The post thumbnail image tag.
  def get_the_post_thumbnail(post = nil, size = 'post-thumbnail', attr = {})
    post = get_post( post )
    return '' if post.nil?
    post_thumbnail_id = get_post_thumbnail_id( post )
    # Filters the post thumbnail size.
    size = apply_filters('post_thumbnail_size', size, post.id)
    if post_thumbnail_id.blank?
      html = ''
    else
      # Fires before fetching the post thumbnail HTML.
      # Provides "just in time" filtering of all filters in wp_get_attachment_image()
      # TODO is it needed?
      # do_action('begin_fetch_post_thumbnail_html', post.id, post_thumbnail_id, size)
      # if in_the_loop()
      #   update_post_thumbnail_cache()
      # end
      html = wp_get_attachment_image(post_thumbnail_id, size, false, attr)
      #
      # Fires after fetching the post thumbnail HTML.
      # do_action('end_fetch_post_thumbnail_html', post.id, post_thumbnail_id, size)
    end
    # Filters the post thumbnail HTML.
    apply_filters('post_thumbnail_html', html, post.id, post_thumbnail_id, size, attr)
  end

 # Return the post thumbnail URL.
 #
 # @param [int|WP_Post]  post Optional. Post ID or WP_Post object.  Default is global `$post`.
 # @param [String|array] size Optional. Registered image size to retrieve the source for or a flat
 #                           array of height and width dimensions. Default 'post-thumbnail'.
 # @return [String|false] Post thumbnail URL or false if no URL is available.
  def get_the_post_thumbnail_url( post = nil, size = 'post-thumbnail' )
    post_thumbnail_id = get_post_thumbnail_id(post)
    return false if post_thumbnail_id.blank?
    wp_get_attachment_image_url(post_thumbnail_id, size)
  end

end