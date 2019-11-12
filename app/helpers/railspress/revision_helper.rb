=begin
 * Post revision functions.
 *
 * file wp-includes\revision.php
=end
module Railspress::RevisionHelper

 # Determines if the specified post is a revision.
 #
 # @param [int|WP_Post] post Post ID or post object.
 # @return [false|int] False if not a revision, ID of revision's parent otherwise.
 def wp_is_post_revision(post)
   post = wp_get_post_revision(post)
   return false if post.nil?

   post.post_parent.to_i
 end


 # Gets a post revision.
 #
 # @param [int|WP_Post] post   The post ID or object.
 # @param [string]      output Optional. The required return type. One of OBJECT, ARRAY_A, or ARRAY_N, which correspond to
 #                             a WP_Post object, an associative array, or a numeric array, respectively. Default OBJECT.
 # @param [string]      filter Optional sanitation filter. See sanitize_post().
 # @return [WP_Post|array|null] WP_Post (or array) on success, or null on failure.
 def wp_get_post_revision(post, output = :OBJECT, filter = 'raw')
   revision = get_post(post, :OBJECT, filter)
   return revision if revision.nil?

   return nil if revision.post_type != 'revision'

   if output == :OBJECT
     return revision
   elsif output == :ARRAY_A
     _revision = get_object_vars(revision)
     return _revision
   elsif output == :ARRAY_N
     _revision = array_values(get_object_vars(revision))
     return _revision
   end

   revision
 end

 # Returns all revisions of specified post.
  #
  # @see get_children()
  #
  # @param [int|WP_Post] post_id Optional. Post ID or WP_Post object. Default is global `$post`.
  # @param [array|null]  args    Optional. Arguments for retrieving post revisions. Default null.
  # @return [array] An array of revisions, or an empty array if none.
  def wp_get_post_revisions(post_id = 0, args = nil)
    post = get_post(post_id)

    return {} if post.nil?

    defaults = {
        order: 'DESC',
        orderby: 'post_date', # TODO How is it correct? orderby: 'date ID',
        check_enabled: true,
    }
    args = wp_parse_args(args || {}, defaults)

    if args[:check_enabled] && !wp_revisions_enabled(post)
      return {}
    end

    args = args.merge({
                          post_parent: post.id,
                          post_type: 'revision',
                          post_status: 'inherit',
                      })

    revisions = get_children(args)
    return {} if revisions.nil?

    revisions
  end

  # Determine if revisions are enabled for a given post.
  #
  # @param [WP_Post] post The post object.
  # @return bool True if number of revisions to keep isn't zero, false otherwise.
  def wp_revisions_enabled(post)
    wp_revisions_to_keep(post) != 0
  end

  # Determine how many revisions to retain for a given post.
  #
  # By default, an infinite number of revisions are kept.
  #
  # The constant WP_POST_REVISIONS can be set in wp-config to specify the limit
  # of revisions to keep.
  #
  # @param [WP_Post] post The post object.
  # @return [int] The number of revisions to keep.
  def wp_revisions_to_keep(post)
    num = !defined?(Rails.application.secrets.WP_POST_REVISIONS) || Rails.application.secrets.WP_POST_REVISIONS

    if num == true || 'true'.eql?(num)
      num = -1
    else
      num = num.to_i
    end

    unless post_type_supports(post.post_type, 'revisions')
      num = 0
    end

    # Filters the number of revisions to save for the given post.
    #
    # Overrides the value of WP_POST_REVISIONS.
    apply_filters('wp_revisions_to_keep', num, post).to_i
  end

 # Retrieve formatted date timestamp of a revision (linked to that revisions's page).
 #
 # @param [int|object] revision Revision ID or revision object.
 # @param [bool]       link     Optional, default is true. Link to revisions's page?
 # @return [string|false] i18n formatted datetimestamp or localized 'Current Revision'.
  def wp_post_revision_title(revision, link = true )
    revision = get_post( revision )
    return revision if revision.nil?

    return false unless ['post', 'page', 'revision'].include?  revision.post_type

    # translators: revision date format, see https://secure.php.net/date
	  datef = _x( 'F j, Y @ H:i:s', 'revision date format' )
	# translators: %s: revision date
	autosavef = __( '%s [Autosave]' )
	# translators: %s: revision date
	currentf = __( '%s [Current Revision]' )

	date = date_i18n( datef, strtotime( revision.post_modified ) )
	if ( link && current_user_can( 'edit_post', revision.id ) && link = get_edit_post_link( revision.id ) )
		date = "<a href='#{link}'>#{date}</a>"
	end

	if !wp_is_post_revision(revision)
		date = sprintf(currentf, date )
	elsif wp_is_post_autosave(revision)
		date = sprintf(autosavef, date )
	end

	date
  end

end