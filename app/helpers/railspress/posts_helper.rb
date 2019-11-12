=begin
 * Core Post API
 *
 * file wp-includes\post.php
=end
module Railspress::PostsHelper
  include Railspress::Functions
  include Railspress::Plugin

  # Retrieve attached file path based on attachment ID.
  #
  # By default the path will go through the 'get_attached_file' filter, but
  # passing a true to the $unfiltered argument of get_attached_file() will
  # return the file path unfiltered.
  #
  # The function works by getting the single post meta name, named
  # '_wp_attached_file' and returning it. This is a convenience function to
  # prevent looking up the meta name and provide a mechanism for sending the
  # attached filename through a filter.
  #
  # @param [int]  attachment_id Attachment ID.
  # @param [bool] unfiltered    Optional. Whether to apply filters. Default false.
  # @return [string|false] The file path to where the attached file should be, false otherwise.
  def get_attached_file(attachment_id, unfiltered = false )
    file = get_post_meta(attachment_id, '_wp_attached_file',true)

    # If the file is relative, prepend upload dir.
    if file && file.index('/') != 0 && !file.match('|^.:\\\|')
      uploads = wp_get_upload_dir
      if uploads && uploads['error'].nil?
        file = uploads['basedir'] + "/#{file}";
      end
    end
    return file if unfiltered
    # Filters the attached file based on the given ID.
    apply_filters( 'get_attached_file', file, attachment_id)
  end

  # Retrieve all children of the post parent ID.
  #
  # @param [mixed]  args   Optional. User defined arguments for replacing the defaults. Default empty.
  # @param [String] output Optional. The required return type. One of OBJECT, ARRAY_A, or ARRAY_N, which correspond to
  #                        a WP_Post object, an associative array, or a numeric array, respectively. Default OBJECT.
  # @return Array of children, where the type of each element is determined by $output parameter. Empty array on failure.
  def get_children(args = '', output = :OBJECT)
    kids = {}
    if args.blank?
        if $GLOBALS['post']
          args = { post_parent:  $GLOBALS['post'].post_parent }
        else
          return kids
        end
    elsif args.is_a? Integer
      args = { post_parent: args}
    elsif args.is_a? String
      args = { post_parent: args.to_i}
    elsif args.is_a? Railspress::WpPost
      args = { post_parent: args.post_parent }
    end

    defaults = {
        numberposts: -1,
        post_type: 'any',
        post_status: 'any',
        post_parent: 0,
    }

    r = defaults.merge args

    children = get_posts(r)

    return kids if children.nil?

    return children unless r[:fields].blank?

    # update_post_cache(children)

    children.each do |child|
      kids[child.id] = child
    end

    if output == :OBJECT
      kids
    elsif output == :ARRAY_A
      weeuns = {}
      kids.values.each do |kid|
        weeuns[kid.id] = kid.attributes
      end
      return weeuns
    elsif output == :ARRAY_N
      babes = {}
      kids.values.each do |kid|
        babes[kid.id] = kid.attributes.values
      end
      return babes
    else
      kids
    end
  end

  # Retrieves post data given a post ID or post object.
  #
  # See sanitize_post() for optional $filter values. Also, the parameter
  # `$post`, must be given as a variable, since it is passed by reference.
  #
  # @param [int|WP_Post|null] post   Optional. Post ID or post object. Defaults to global $post.
  # @param [string]           output Optional. The required return type. One of OBJECT, ARRAY_A, or ARRAY_N, which correspond to
  #                                 a WP_Post object, an associative array, or a numeric array, respectively. Default OBJECT.
  # @param [string]           filter Optional. Type of filter to apply. Accepts 'raw', 'edit', 'db',
  #                                 or 'display'. Default 'raw'.
  # @return [WP_Post|array|null] Type corresponding to $output on success or null on failure.
  #                            When $output is OBJECT, a `WP_Post` instance is returned.
  def get_post(post = nil, output = :OBJECT, filter = 'raw')
    # if ( empty( $post ) && isset( $GLOBALS['post'] ) ) { TODO
    #     $post = $GLOBALS['post'];
    # }

    if  post.is_a? Railspress::WpPost
        _post = post
    elsif post.is_a? Integer
      _post = Railspress::WpPost.find(post)
    elsif post.is_a? String
      _post = Railspress::WpPost.find(post.to_i)
     # elsif ( is_object( $post ) ) TODO
     #  if ( empty( $post->filter ) )
     #    $_post = sanitize_post( $post, 'raw' );
     #    $_post = new WP_Post( $_post );
     #   elsif ( 'raw' == $post->filter )
     #    $_post = new WP_Post( $post );
     #   else
     #    $_post = WP_Post::get_instance( $post->ID );
     #    end
     #  else
     #     $_post = WP_Post::get_instance( $post );
      end

      return nil if _post.nil?

      _post = _post.filter( filter )

      if output == :ARRAY_A
        return _post.attributes
      elsif output == :ARRAY_N
        return _post.attributes.values
      end

      return _post
      end

  # Retrieve the post status based on the post ID.
  #
  # If the post ID is of an attachment, then the parent post status will be given instead.
  #
  # @param [int|WP_Post] post Optional. Post ID or post object. Defaults to global $post..
  # @return [string|false] Post status on success, false on failure.
  def get_post_status(post = nil)
    post = get_post(post)

    return false unless post.is_a? Railspress::WpPost

    if 'attachment' == post.post_type
      return 'private' if 'private' == post.post_status
      # Unattached attachments are assumed to be published.
      return 'publish' if (('inherit' == post.post_status) && (0 == post.post_parent))

      # Inherit status from the parent.
      if post.post_parent && post.id != post.post_parent
        parent_post_status = get_post_status(post.post_parent)
        if 'trash' == parent_post_status
          return get_post_meta(post.post_parent, '_wp_trash_meta_status', true)
        else
          return parent_post_status
        end
      end
    end
    # Filters the post status.
    apply_filters('get_post_status', post.post_status, post)
  end

  # Get extended entry info (<!--more-->).
  #
  # There should not be any space after the second dash and before the word
  # 'more'. There can be text or space(s) after the word 'more', but won't be
  # referenced.
  #
  # The returned array has 'main', 'extended', and 'more_text' keys. Main has the text before
  # the `<!--more-->`. The 'extended' key has the content after the
  # `<!--more-->` comment. The 'more_text' key has the custom "Read More" text.
  #
  # return array Post before ('main'), after ('extended'), and custom read more ('more_text').
  def get_extended(post)
    # Match the new style more links.
    matches = post.scan(/<!--more-->/i)
    if !matches.blank?
      main, extended = post.split(matches[0], 2)
      more_text = matches[1]
    else
      main = post
      extended = ''
      more_text = ''
    end

    # leading and trailing whitespace.
    main = main.gsub(/^[\s]*(.*)[\s]*$/, '\\1')
    extended = extended.gsub(/^[\s]*(.*)[\s]*$/, '\\1')
    more_text = more_text.gsub(/^[\s]*(.*)[\s]*$/, '\\1') unless more_text.nil?

    {main: main, extended: extended, more_text: more_text}
  end

  # Retrieves a post type object by name.
  #
  # @global array $wp_post_types List of post types.
  #
  # @see register_post_type()
  #
  # @param [string] post_type The name of a registered post type.
  # @return WP_Post_Type|null WP_Post_Type object if it exists, null otherwise.
  def get_post_type_object(post_type)

    if !( post_type.is_a?(Numeric) || post_type.is_a?(FalseClass) || post_type.is_a?(TrueClass)) || GLOBAL.wp_post_types[ post_type ].blank?
        return nil
    end

    GLOBAL.wp_post_types[post_type]
  end


  # Get a list of all registered post type objects.
  #
  # @global array $wp_post_types List of post types.
  #
  # @see register_post_type() for accepted arguments.
  #
  # @param [array|string] args     Optional. An array of key => value arguments to match against
  #                                the post type objects. Default empty array.
  # @param [string]       output   Optional. The type of output to return. Accepts post type 'names'
  #                                or 'objects'. Default 'names'.
  # @param [string]       operator Optional. The logical operation to perform. 'or' means only one
  #                                element from the array needs to match; 'and' means all elements
  #                                must match; 'not' means no elements may match. Default 'and'.
  # @return [string[]|WP_Post_Type[]] An array of post type names or objects.
  def get_post_types(args = {}, output = 'names', operator = 'and')
    field = ( 'names' == output ) ? 'name' : false

    wp_filter_object_list(GLOBAL.wp_post_types, args, operator, field)
  end

  # Check a post type's support for a given feature.
  #
  # @global array $_wp_post_type_features
  #
  # @param [string] post_type The post type being checked.
  # @param [string] feature   The feature being checked.
  # @return bool Whether the post type supports the given feature.
  def post_type_supports(post_type, feature)
    !GLOBAL._wp_post_type_features[post_type][feature].nil?
  end

  # Retrieves an array of the latest posts, or posts matching the given criteria.
  #
  # @param [array] $args {
  #     Optional. Arguments to retrieve posts. See WP_Query::parse_query() for all
  #     available arguments.
  #
  #     @type int        numberposts      Total number of posts to retrieve. Is an alias of $posts_per_page
  #                                        in WP_Query. Accepts -1 for all. Default 5.
  #     @type int|string category         Category ID or comma-separated list of IDs (this or any children).
  #                                       Is an alias of $cat in WP_Query. Default 0.
  #     @type array      include          An array of post IDs to retrieve, sticky posts will be included.
  #                                       Is an alias of $post__in in WP_Query. Default empty array.
  #     @type array      exclude          An array of post IDs not to retrieve. Default empty array.
  #     @type bool       suppress_filters Whether to suppress filters. Default true.
  # }
  # @return Array of post objects or post IDs.
  def get_posts(args = nil)
    defaults = {
        numberposts: 5,
        category: 0,
        orderby: 'date',
        order: 'DESC',
        include: [],
        exclude: [],
        meta_key: '',
        meta_value: '',
        post_type: 'post',
        suppress_filters: true,
    }

    r = defaults.merge(args || {})
    if r[:post_status].blank?
       r[:post_status] = ('attachment' == r[:post_type]) ? 'inherit' : 'publish'
    end
    if !r[:numberposts].blank? && r[:posts_per_page].blank?
       r[:posts_per_page] = r[:numberposts]
    end
    if !r[:category].blank?
        r[:cat] = r[:category]
    end
    if !r[:include].blank?
      incposts           = wp_parse_id_list( r[:include] )
      r[:posts_per_page] = incposts.size # only the number of posts included
      r[:post__in]       = incposts
    elsif  !r[:exclude].blank?
      r[:post__not_in] = wp_parse_id_list( r[:exclude] )
    end

    r[:ignore_sticky_posts] = true
    r[:no_found_rows]       = true

    # $get_posts = new WP_Query;
    # return $get_posts->query( $r );
    where_clause = {post_parent: r[:post_parent], post_type: r[:post_type], post_status: r[:post_status]}
    where_clause[:id] = r[:post__in]  unless r[:post__in].nil?
    Railspress::WpPost.where(where_clause)
        .limit(r[:posts_per_page] == -1 ? nil : r[:posts_per_page])
        .order(r[:orderby] => r[:order].to_sym)
  end

  # Retrieves a post meta field for the given post ID.
  def get_post_meta(post_id, key = '', single = false)
    md = get_metadata('post', post_id, key, single)
    md.symbolize_keys! if md.is_a? Hash
    md
  end

  # Sanitize every post field.
  #
  # If the context is 'raw', then the post object or array will get minimal sanitization of the integer fields.
  #
  # @param [object|WP_Post|array] post    The Post Object or Array
  # @param [string]               context Optional. How to sanitize post fields.
  #                                       Accepts 'raw', 'edit', 'db', or 'display'. Default 'display'.
  # @return object|WP_Post|array The now sanitized Post Object or Array (will be the same type as $post).
  def sanitize_post(post, context = 'display')
    if !post.kind_of?(Hash) # obj??
      # Check if post already filtered for this context.
      return post if post.filter == context
      post.id = 0 if post.id.blank?
      post.attributes.each do |field|
        post.write_attribute(field, sanitize_post_field(field, post.read_attribute(field), post.id, context))
      end
      post.filter = context
    elsif post.kind_of?(Hash)
      # Check if post already filtered for this context.
      return post if post.filter == context
      post['id'] = 0 if post.id.blank?
      post.each {|field, value| post[field] = sanitize_post_field(field, value, post['id'], context)}
      post.filter = context
    end
    return post
  end


 # Sanitize post field based on context.
 #
 # Possible context values are:  'raw', 'edit', 'db', 'display', 'attribute' and
 # 'js'. The 'display' context is used by default. 'attribute' and 'js' contexts
 # are treated like 'display' when calling filters.
 #
 # @param [string] field   The Post Object field name.
 # @param [mixed]  value   The Post Object value.
 # @param [int]    post_id Post ID.
 # @param [string] context Optional. How to sanitize post fields. Looks for 'raw', 'edit',
 #                         'db', 'display', 'attribute' and 'js'. Default 'display'.
 # @return [mixed] Sanitized value.
 def sanitize_post_field(field, value, post_id, context = 'display')
    int_fields = ['ID', 'post_parent', 'menu_order']
    if int_fields.include? field
        value = value.to_i
    end

    # Fields which contain arrays of integers.
    array_int_fields = ['ancestors']
    if array_int_fields.include? field
      value = value.map{|i| i.to_i.abs}
      return value
    end

    return value if 'raw' == context

    prefixed = false
    if field.include? 'post_'
      prefixed        = true
      field_no_prefix = field.gsub('post_', '')
    end

    if 'edit' == context
      format_to_edit = [ 'post_content', 'post_excerpt', 'post_title', 'post_password' ]
      if prefixed
         # Filters the value of a specific post field to edit.
         value = apply_filters("edit_#{field}", value, post_id)
         # Filters the value of a specific post field to edit.
         value = apply_filters( "#{field_no_prefix}_edit_pre", value, post_id )
      else
         value = apply_filters( "edit_post_#{field}", value, post_id )
      end

      if format_to_edit.include?(field)
        if 'post_content' == field
          value = format_to_edit(value, true) # TODO implement function user_can_richedit() from general-template.php
        else
          value = format_to_edit(value)
        end
      else
        value = esc_attr(value)
      end
    elsif 'db' == context
      if prefixed
        # Filters the value of a specific post field before saving.
        value = apply_filters("pre_#{field}", value)
        # Filters the value of a specific field before saving.
        value = apply_filters( "#{field_no_prefix}_save_pre", value )
      else
        value = apply_filters( "pre_post_#{field}", value )
        # Filters the value of a specific post field before saving.
        value = apply_filters( "{$field}_pre", value )
      end
     else
       # Use display filters by default.
       if prefixed
         # Filters the value of a specific post field for display.
         value = apply_filters("{$field}", value, post_id, context)
       else
         value = apply_filters("post_{$field}", value, post_id, context)
       end
       if 'attribute' == context
         value = esc_attr(value)
       elsif 'js' == context
         value = esc_js(value)
       end
     end
    value
   end

  # Build the URI path for a page.
  #
  # Sub pages will be in the "directory" under the parent page post name.
  #
  # @param [WP_Post|object|int] page Optional. Page ID or WP_Post object. Default is global $post.
  # @return [string|false] Page URI, false on error.
  def get_page_uri(page = 0)
    page = get_post(page) unless page.is_a?(Railspress::WpPost)
    return false if page.nil?

    uri = page.post_name

    ancestor = page.parent
    until ancestor.nil?
      uri = ancestor.post_name + '/' + uri unless ancestor.post_name.nil?
      ancestor = ancestor.parent
    end

    # Filters the URI for a page.
    apply_filters('get_page_uri', uri, page)
  end


  # Retrieve attachment meta field for attachment ID.
  #
  # @since 2.1.0
  #
  # @param [int]  attachment_id Attachment post ID. Defaults to global $post.
  # @param [bool] unfiltered    Optional. If true, filters are not run. Default false.
  # @return Attachment meta field. False on failure.
  def wp_get_attachment_metadata(attachment_id = 0, unfiltered = false)
    attachment_id = attachment_id.to_i
    post = get_post(attachment_id )
    return false if post.nil?

    data = get_post_meta(post.id, '_wp_attachment_metadata', true)

    return data if unfiltered

    # Filters the attachment meta data.
    apply_filters('wp_get_attachment_metadata', data, post.id)
  end


  # Retrieve the URL for an attachment.
  #
  # @param [int] attachment_id Optional. Attachment post ID. Defaults to global $post.
  # @return [string|false] Attachment URL, otherwise false.
  def wp_get_attachment_url(attachment_id = 0)
    attachment_id = attachment_id.to_i
    post = get_post(attachment_id)
    return false if post.nil?
    return false if post.post_type != 'attachment'

    url = ''
    # Get attached file.
    if (file = get_post_meta(post.id, '_wp_attached_file', true))
      # Get upload directory.
      uploads = wp_get_upload_dir
      if uploads && !uploads[:error]
        # Check that the upload base exists in the file location.
        if file.index(uploads[:basedir]) == 0
          # Replace file location with url location.
          url = file.gsub(uploads[:basedir], uploads[:baseurl])
        elsif file.include?('wp-content/uploads')
          # Get the directory name relative to the basedir (back compat for pre-2.7 uploads)
          url = trailingslashit(uploads[:baseurl] + '/' + _wp_get_attachment_relative_path(file)) + wp_basename(file)
        else
          # It's a newly-uploaded file, therefore file is relative to the basedir.
          url = uploads[:baseurl] + "/#{file}"
        end
      end
    end

    # If any of the above options failed, Fallback on the GUID as used pre-2.7, not recommended to rely upon this.
    url = get_the_guid(post.id) if url.blank?

    # On SSL front end, URLs should be HTTPS.
    # TODO if is_ssl() && !is_admin() && 'wp-login.php' != $GLOBALS['pagenow']
    #   url = set_url_scheme(url)
    # end

    # Filters the attachment URL.
    url = apply_filters('wp_get_attachment_url', url, post.id)

    return false if url.blank?
    url
  end

  # Retrieve thumbnail for an attachment.
  #
  # @param [int] post_id Optional. Attachment ID. Default 0.
  # @return [string|false] False on failure. Thumbnail file path on success.
  def wp_get_attachment_thumb_file(post_id = 0)
    post_id = post_id.to_i
    post = get_post post_id
    return false if post.nil?

    imagedata = wp_get_attachment_metadata(post.id)
    return false unless imagedata.is_a? Hash
    imagedata.symbolize_keys!

    file = get_attached_file post.id

    unless imagedata[:thumb].blank?
      thumbfile = file.gsub(wp_basename(file), imagedata[:thumb])
      if thumbfile && File.exist?(thumbfile)
        # Filters the attachment thumbnail file path.
        return apply_filters('wp_get_attachment_thumb_file', thumbfile, post.id)
      end
    end
    return false
  end


  # Verifies an attachment is of a given type.
  # @param [String]      type Attachment type. Accepts 'image', 'audio', or 'video'.
  # @param [int|WP_Post] post Optional. Attachment ID or object. Default is global $post.
  # @return [bool] True if one of the accepted types, false otherwise.
  def wp_attachment_is(type, post = nil)
    post = get_post(post)
    return false if post.nil?

    return false if (!file = get_attached_file(post.id))

    return true if post.post_mime_type.index(type + '/') == 0

    check = wp_check_filetype(file)
    return false if check[:ext].blank?

    ext = check[:ext]

    if 'import' != post.post_mime_type
      return type == ext
    end

    case type
    when 'image'
      ['jpg', 'jpeg', 'jpe', 'gif', 'png'].include? ext
    when 'audio'
      wp_get_audio_extensions.include? ext
    when 'video'
      wp_get_video_extensions.include? ext
    else
      type == ext
    end
  end

  # Determines whether an attachment is an image.
  #
  # @param [int|WP_Post] post Optional. Attachment ID or object. Default is global $post.
  # @return [bool] Whether the attachment is an image.
  def wp_attachment_is_image(post = nil)
    wp_attachment_is('image', post)
  end


end
