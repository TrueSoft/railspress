=begin
 * WordPress API for media display.
 *
 * file wp-includes\media.php
=end
module Railspress::MediaHelper

  # Retrieve additional image sizes.
  #
  # @return array Additional images size data.
  def wp_get_additional_image_sizes
    # TODO global $_wp_additional_image_sizes;
    # if ( ! $_wp_additional_image_sizes ) {
    #     $_wp_additional_image_sizes = array();
    # }
    # return $_wp_additional_image_sizes;
    {}
  end

  # Scale down the default size of an image.
  #
  # This is so that the image is a better fit for the editor and theme.
  #
  # The `$size` parameter accepts either an array or a string. The supported string
  # values are 'thumb' or 'thumbnail' for the given thumbnail size or defaults at
  # 128 width and 96 height in pixels. Also supported for the string value is
  # 'medium', 'medium_large' and 'full'. The 'full' isn't actually supported, but any value other
  # than the supported will result in the content_width size or 500 if that is
  # not set.
  #
  # Finally, there is a filter named {@see 'editor_max_image_size'}, that will be
  # called on the calculated array for width and height, respectively. The second
  # parameter will be the value that was in the $size parameter. The returned
  # type for the hook is an array with the width as the first element and the
  # height as the second element.
  #
  # @global int   $content_width
  #
  # @param [int]          width   Width of the image in pixels.
  # @param [int]          height  Height of the image in pixels.
  # @param [string|array] size    Optional. Image size. Accepts any valid image size, or an array
  #                               of width and height values in pixels (in that order).
  #                               Default 'medium'.
  # @param [string]       context Optional. Could be 'display' (like in a theme) or 'edit'
  #                               (like inserting into an editor). Default nil.
  # @return [array] Width and height of what the result image should resize to.
  def image_constrain_size_for_editor(width, height, size = 'medium', context = nil )
    # global $content_width; TODO content_width

    _wp_additional_image_sizes = wp_get_additional_image_sizes

    if context.nil?
      context =  is_admin ? 'edit' : 'display'
    end

    if size.is_a? Array
      max_width = size[0]
      max_height = size[1]
    elsif size == 'thumb' || size == 'thumbnail'
      max_width = get_option('thumbnail_size_w').to_i
      max_height = get_option('thumbnail_size_h').to_i
      # last chance thumbnail size defaults
      if max_width == 0 && max_height == 0
        max_width = 128
        max_height = 96
      end
    elsif size == 'medium'
      max_width = get_option('medium_size_w', 0).to_i
      max_height = get_option('medium_size_h', 0).to_i
    elsif size == 'medium_large'
      max_width = get_option('medium_large_size_w').to_i
      max_height = get_option('medium_large_size_h').to_i
      # if content_width.to_i > 0
      #     max_width = [content_width.to_i, max_width].min
      # end
    elsif size == 'large'
      # We're inserting a large size image into the editor. If it's a really
      # big image we'll scale it down to fit reasonably within the editor
      # itself, and within the theme's content width if it's known. The user
      # can resize it in the editor if they wish.
      max_width = get_option('large_size_w').to_i
      max_height = get_option('large_size_h').to_i
      # if ( intval( $content_width ) > 0 ) {
      #     $max_width = min( intval( $content_width ), $max_width );
      # }
    elsif !_wp_additional_image_sizes.blank? && _wp_additional_image_sizes[size]
      max_width = _wp_additional_image_sizes[size]['width'].to_i
      max_height = _wp_additional_image_sizes[size]['height'].to_i
      # Only in admin. Assume that theme authors know what they're doing.
      # if ( intval( $content_width ) > 0 && 'edit' === $context ) {
      # $max_width = min( intval( $content_width ), $max_width );
      # }
    else # $size == 'full' has no constraint
      max_width = width
      max_height = height
    end

	  # Filters the maximum image size dimensions for the editor.
	  list = apply_filters( 'editor_max_image_size', [max_width, max_height], size, context )

	  wp_constrain_dimensions(width, height, list[0], list[1])
  end

  # Retrieve width and height attributes using given width and height values.
  #
  # Both attributes are required in the sense that both parameters must have a
  # value, but are optional in that if you set them to false or null, then they
  # will not be added to the returned string.
  #
  # You can set the value using a string, but it will only take numeric values.
  # If you wish to put 'px' after the numbers, then it will be stripped out of
  # the return.
  #
  # @param [int|String] width  Image width in pixels.
  # @param [int|String] height Image height in pixels.
  # @return [String] HTML attributes for width and, or height.
  def image_hwstring(width, height)
    out = ''
    if width
      out += 'width="' + width.to_i.to_s + '" '
    end
    if height
      out += 'height="' + height.to_i.to_s + '" '
    end
    out
  end

  # Scale an image to fit a particular size (such as 'thumb' or 'medium').
  #
  # Array with image url, width, height, and whether is intermediate size, in
  # that order is returned on success is returned. $is_intermediate is true if
  # $url is a resized image, false if it is the original.
  #
  # The URL might be the original image, or it might be a resized version. This
  # function won't create a new resized copy, it will just return an already
  # resized one if it exists.
  #
  # A plugin may use the {@see 'image_downsize'} filter to hook into and offer image
  # resizing services for images. The hook must return an array with the same
  # elements that are returned in the function. The first element being the URL
  # to the new image that was resized.
  #
  # @since 2.5.0
  #
  # @param [int]          id   Attachment ID for image.
  # @param [Array|String] size Optional. Image size to scale to. Accepts any valid image size,
  #                           or an array of width and height values in pixels (in that order).
  #                           Default 'medium'.
  # @return [false|Array] Array containing the image URL, width, height, and boolean for whether
  #                     the image is an intermediate size. False on failure.
  def image_downsize(id, size = 'medium')
    is_image = wp_attachment_is_image id

	  # Filters whether to preempt the output of image_downsize().
	  #
	  # Passing a truthy value to the filter will effectively short-circuit
	  # down-sizing the image, returning that value as output instead.
    if (out = apply_filters('image_downsize', false, id, size))
      return out
    end

    img_url          = wp_get_attachment_url(id)
    meta             = wp_get_attachment_metadata(id)
    meta.symbolize_keys! if meta.is_a?(Hash)
    width, height    = 0, 0
    is_intermediate  = false
    img_url_basename = wp_basename(img_url)

    # If the file isn't an image, attempt to replace its URL with a rendered image from its meta.
	  # Otherwise, a non-image type could be returned.
	unless is_image
		if !meta[:sizes].blank?
			img_url          = img_url.gsub(img_url_basename, meta[:sizes]['full']['file'])
			img_url_basename = meta[:sizes]['full']['file']
			width            = meta[:sizes]['full']['width']
			height           = meta[:sizes]['full']['height']
		 else
			return false
		end
	end

	# try for a new style intermediate size
	if ( intermediate = image_get_intermediate_size( id, size ) )
		img_url         = img_url.gsub(img_url_basename, intermediate['file'])
		width           = intermediate['width']
		height          = intermediate['height']
		is_intermediate = true
  elsif size == 'thumbnail'
		# fall back to the old thumbnail
    thumb_file = wp_get_attachment_thumb_file(id)
		if thumb_file
      info = Dimensions.dimensions(thumb_file)
      if info
        img_url         = img_url.gsub(img_url_basename, wp_basename( thumb_file ))
        width           = info[0]
        height          = info[1]
        is_intermediate = true
		  end
		end
	end
	if (width.blank? || width == 0) && (height.blank? || height == 0) && meta[:width] && meta[:height]
		# any other type: use the real image
		width  = meta[:width]
		height = meta[:height]
	end

	if img_url
		# we have the actual image size, but might need to further constrain it if content_width is narrower
		width, height  = image_constrain_size_for_editor(width, height, size )

		[img_url, width, height, is_intermediate]
  else
    false
	end
  end

  # Calculates the new dimensions for a down-sampled image.
  #
  # If either width or height are empty, no constraint is applied on
  # that dimension.
  #
  # @param [int] current_width  Current width of the image.
  # @param [int] current_height Current height of the image.
  # @param [int] max_width      Optional. Max width in pixels to constrain to. Default 0.
  # @param [int] max_height     Optional. Max height in pixels to constrain to. Default 0.
  # @return array First item is the width, the second item is the height.
  def wp_constrain_dimensions(current_width, current_height, max_width = 0, max_height = 0)
    return [current_width, current_height] if max_width == 0 && max_height == 0

    width_ratio = height_ratio = 1.0
    did_width = did_height = false

    if max_width > 0 && current_width > 0 && current_width > max_width
      width_ratio = max_width / current_width
      did_width = true
    end

    if max_height > 0 && current_height > 0 && current_height > max_height
      height_ratio = max_height / current_height
      did_height = true
    end

    # Calculate the larger/smaller ratios
    smaller_ratio = [width_ratio, height_ratio].min
    larger_ratio = [width_ratio, height_ratio].max

    if (current_width * larger_ratio).round > max_width || (current_height * larger_ratio).round > max_height
      # The larger ratio is too big. It would result in an overflow.
      ratio = smaller_ratio
    else
      # The larger ratio fits, and is likely to be a more "snug" fit.
      ratio = larger_ratio
    end

    # Very small dimensions may result in 0, 1 should be the minimum.
    w = [1, (current_width * ratio).round].max
    h = [1, (current_height * ratio).round].max

    # Sometimes, due to rounding, we'll end up with a result like this: 465x700 in a 177x177 box is 117x176... a pixel short
    # We also have issues with recursive calls resulting in an ever-changing result. Constraining to the result of a constraint should yield the original result.
    # Thus we look for dimensions that are one pixel shy of the max value and bump them up

    # Note: did_width means it is possible $smaller_ratio == $width_ratio.
    if did_width && w == max_width - 1
      w = max_width # Round it up
    end

    # Note: did_height means it is possible $smaller_ratio == $height_ratio.
    if did_height && h == max_height - 1
      h = max_height # Round it up
    end

    # Filters dimensions to constrain down-sampled images to.
    apply_filters('wp_constrain_dimensions', [w, h], current_width, current_height, max_width, max_height)
  end

  # Retrieves the image's intermediate size (resized) path, width, and height.
  #
  # The $size parameter can be an array with the width and height respectively.
  # If the size matches the 'sizes' metadata array for width and height, then it
  # will be used. If there is no direct match, then the nearest image size larger
  # than the specified size will be used. If nothing is found, then the function
  # will break out and return false.
  #
  # The metadata 'sizes' is used for compatible sizes that can be used for the
  # parameter $size value.
  #
  # The url path will be given, when the $size parameter is a string.
  #
  # If you are passing an array for the $size, you should consider using
  # add_image_size() so that a cropped version is generated. It's much more
  # efficient than having to find the closest-sized image and then having the
  # browser scale down the image.
  #
  # @param [int]          post_id Attachment ID.
  # @param [array|string] size    Optional. Image size. Accepts any valid image size, or an array of width and height
  #                               values in pixels (in that order). Default 'thumbnail'.
  # @return false|array $data {
  #     Array of file relative path, width, and height on success. Additionally includes absolute
  #     path and URL if registered size is passed to $size parameter. False on failure.
  #
  #     @type string file   Image's path relative to uploads directory
  #     @type int    width  Width of image
  #     @type int    height Height of image
  #     @type string path   Image's absolute filesystem path.
  #     @type string url    Image's URL.
  # }
def image_get_intermediate_size(post_id, size = 'thumbnail')
  imagedata = wp_get_attachment_metadata( post_id )
	if size.blank? || !imagedata.kind_of?(Hash) || imagedata[:sizes].blank?
		return false
	end

	data = {}

	# Find the best match when 'size' is an array.
  if size.kind_of?(Array)
        candidates = {}

        if imagedata[:file].blank? && !imagedata[:sizes]['full'].blank?
            imagedata[:height] = imagedata[:sizes]['full']['height']
            imagedata[:width]  = imagedata[:sizes]['full']['width']
        end
        imagedata[:sizes].each_pair do |_size, data|
            # If there's an exact match to an existing image size, short circuit.
            if data['width'] == size[0] && data['height'] == size[1]
              candidates[data['width'] * data['height'] ] = data
              break
            end

			      # If it's not an exact match, consider larger sizes with the same aspect ratio.
            if data['width'] >= size[0] && data['height'] >= size[1]
              # If '0' is passed to either size, we test ratios against the original file.
              if 0 == size[0] || 0 == size[1]
                same_ratio = wp_image_matches_ratio(data['width'], data['height'], imagedata[:width], imagedata[:height] );
              else
                same_ratio = wp_image_matches_ratio(data['width'], data['height'], size[0], size[1] );
              end

              if same_ratio
                  candidates[ data['width'] * data['height'] ] = data
              end
            end
        end

        if !candidates.empty?
            # Sort the array by size if we have more than one candidate.
            if 1 < candidates.length
              candidates = candidates.sort.to_h
            end

            data = candidates.shift

         # When the size requested is smaller than the thumbnail dimensions, we
         # fall back to the thumbnail size to maintain backward compatibility with
         # pre 4.6 versions of WordPress.
         elsif ( ! empty( imagedata[:sizes]['thumbnail'] ) && imagedata[:sizes]['thumbnail']['width'] >= size[0] && imagedata[:sizes]['thumbnail']['width'] >= size[1] )
          data = imagedata['sizes']['thumbnail']
         else
            return false
         end

        # Constrain the width and height attributes to the requested values.
         data['width'], data['height'] = image_constrain_size_for_editor(data['width'], data['height'], size )

        elsif !imagedata[:sizes][size].blank?
          data = imagedata[:sizes][size]
        end

        # If we still don't have a match at this point, return false.
        return false if data.blank?

	# include the full filesystem path of the intermediate file
	if data[:path].blank? && !data[:file].blank? && !imagedata[:file].blank?
		file_url     = wp_get_attachment_url( post_id )
		data[:path] = path_join( dirname( imagedata[:file] ), data[:file] )
		data[:url]  = path_join( dirname( file_url ), data[:file] )
	end

	# Filters the output of image_get_intermediate_size()
	apply_filters('image_get_intermediate_size', data, post_id, size)
end

  # Get an HTML img element representing an image attachment
  def wp_get_attachment_image(attachment_id, size = 'thumbnail', icon = false, attr = '')
    html  = ''
    image = wp_get_attachment_image_src(attachment_id, size, icon)
    unless image.blank?
      src, width, height = image
      hwstring   = image_hwstring(width, height)
      size_class = size
      if size_class.kind_of?(Array)
        size_class = size_class.join('x')
      end
      attachment   = get_post( attachment_id )
      default_attr = {
          src: src,
          class: "attachment-#{size_class} size-#{size_class}",
          alt: strip_tags(get_post_meta(attachment_id, '_wp_attachment_image_alt', true ))
      }
      default_attr[:alt].strip! unless default_attr[:alt].nil?
      attr = wp_parse_args(attr, default_attr)

      # Generate 'srcset' and 'sizes' if not already present.
      if attr[:srcset].blank?
        image_meta = wp_get_attachment_metadata( attachment_id )

        if image_meta.kind_of?(Array)
          size_array = [ width.to_i.abs, height.to_i.abs ]
          srcset     = wp_calculate_image_srcset( size_array, src, image_meta, attachment_id )
          sizes      = wp_calculate_image_sizes( size_array,  src, image_meta, attachment_id )

          if srcset && ( sizes || !attr[:sizes].empty? )
            attr[:srcset] = srcset

            if attr[:sizes].empty
              attr[:sizes] = sizes
            end
          end
        end
      end

      # Filters the list of attachment image attributes.
      attr = apply_filters( 'wp_get_attachment_image_attributes', attr, attachment, size)
      attr.transform_values!{|v| esc_attr(v) }
      html = "<img #{hwstring}".gsub(/\s$/, '')
      attr.each_pair do |name, value|
        html += " #{name}=" + '"' + value + '"'
      end
      html += ' />'
    end
    return html
  end

  # Get the URL of an image attachment.
  #
  # @param [int]          attachment_id Image attachment ID.
  # @param [string|array] size          Optional. Image size to retrieve. Accepts any valid image size, or an array
  #                                      of width and height values in pixels (in that order). Default 'thumbnail'.
  # @param [bool]         icon          Optional. Whether the image should be treated as an icon. Default false.
  # @return [string|false] Attachment URL or false if no image is available.
  def wp_get_attachment_image_url(attachment_id, size = 'thumbnail', icon = false)
    image = wp_get_attachment_image_src(attachment_id, size, icon)
    if image.length >= 1
      image[0]
    else
      false
    end
  end

  # Get the attachment path relative to the upload directory.
  #
  # @param [string] file Attachment file name.
  # @return [string] Attachment path relative to the upload directory.
  def _wp_get_attachment_relative_path( file )
    dirname = File.dirname( file )
    return '' if dirname == '.'

    if dirname.include? 'wp-content/uploads'
      # Get the directory name relative to the upload directory (back compat for pre-2.7 uploads)
      dirname = dirname[dirname.index('wp-content/uploads') + 18 .. -1]
      dirname.gsub!(/^\//, '')
    end
    dirname
  end

  # Returns a filtered list of WP-supported audio formats.
  #
  # @return [Array] Supported audio formats.
  def wp_get_audio_extensions
    # Filters the list of supported audio formats.
    apply_filters('wp_audio_extensions', ['mp3', 'ogg', 'flac', 'm4a', 'wav'])
  end

  # Returns a filtered list of WP-supported video formats.
  #
  # @return array List of supported video formats.
  def wp_get_video_extensions()
    # Filters the list of supported video formats.
    apply_filters('wp_video_extensions', ['mp4', 'm4v', 'webm', 'ogv', 'flv'])
  end

  # Retrieve an image to represent an attachment.
  #
  # A mime icon for files, thumbnail or intermediate size for images.
  #
  # The returned array contains four values: the URL of the attachment image src,
  # the width of the image file, the height of the image file, and a boolean
  # representing whether the returned array describes an intermediate (generated)
  # image size or the original, full-sized upload.
  #
  # @param attachment_id Image attachment ID.
  # @param size          Optional. Image size. Accepts any valid image size, or an array of width
  #                                    and height values in pixels (in that order). Default 'thumbnail'.
  # @param icon          Optional. Whether the image should be treated as an icon. Default false.
  # @return false|array Returns an array (url, width, height, is_intermediate), or false, if no image is available.
  def wp_get_attachment_image_src( attachment_id, size = 'thumbnail', icon = false )
    # get a thumbnail or intermediate image if there is one
    image = image_downsize( attachment_id, size )
    if !image
      if icon
        src = wp_mime_type_icon(attachment_id)
        if src
          # This filter is documented in wp-includes/post.php
          icon_dir = apply_filters('icon_dir', Railspress.ABSPATH + Railspress.WPINC + '/images/media')

          src_file = icon_dir + '/' + wp_basename(src)
          width, height = Dimensions.dimensions(src_file)
          if width && height
            image = [src, width, height]
          end
        end
      end

    end
    # Filters the image src result.
    apply_filters( 'wp_get_attachment_image_src', image, attachment_id, size, icon)
  end

end