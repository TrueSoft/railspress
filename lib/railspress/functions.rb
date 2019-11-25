=begin
 * Main WordPress API
 *
 * file wp-includes\functions.php
=end
module Railspress::Functions

  # Retrieve the current time based on specified type.
  #
  # The 'mysql' type will return the time in the format for MySQL DATETIME field.
  # The 'timestamp' type will return the current timestamp.
  # Other strings will be interpreted as PHP date formats (e.g. 'Y-m-d').
  #
  # If $gmt is set to either '1' or 'true', then both types will use GMT time.
  # if $gmt is false, the output is adjusted with the GMT offset in the WordPress option.
  #
  # @param [string]   type Type of time to retrieve. Accepts 'mysql', 'timestamp', or PHP date format string (e.g. 'Y-m-d').
  # @param [int|bool] gmt  Optional. Whether to use GMT timezone. Default false.
  # @return [int|string] Integer if $type is 'timestamp', string otherwise.
  def current_time(type, gmt = 0)
    nil # TODO implement current_time
    # case type
    # when 'mysql'
    #   (gmt) ? gmdate('Y-m-d H:i:s') : gmdate('Y-m-d H:i:s', (time() + (get_option('gmt_offset') * HOUR_IN_SECONDS)))
    # when 'timestamp'
    #   (gmt) ? time() : time() + (get_option('gmt_offset') * HOUR_IN_SECONDS)
    # else
    #   (gmt) ? gmdate($type) : gmdate($type, time() + (get_option('gmt_offset') * HOUR_IN_SECONDS))
    # end
  end

  # Unserialize value only if it was serialized.
  #
  # @param [string] original Maybe unserialized original, if is needed.
  # @return Unserialized data can be any type.
  def maybe_unserialize(original)
    if is_serialized(original) # don't attempt to unserialize data that wasn't serialized going in
      # PHP.unserialize original
      PhpSerialization.load(original)
    else
      original
    end
  end

  # Check value to find if it was serialized.
  #
  # If $data is not an string, then returned value will always be false.
  # Serialized data is always a string.
  #
  # @param [string] data   Value to check to see if was serialized.
  # @param [bool]   strict Optional. Whether to be strict about the end of the string. Default true.
  # @return [bool] False if not serialized and true if it was.
  def is_serialized(data, strict = true)
    # if it isn't a string, it isn't serialized.
    return false unless data.is_a? String
    data.strip!
    return true if 'N;' == data
    return false if data.length < 4
    return false if data[1] != ':'
    if strict
      lastc = data[-1]
      return false if lastc != ';' && lastc != '}'
    else
      semicolon = data.include? ';'
      brace = data.include? '}'
      # Either ; or } must exist.
      return false if !semicolon && !brace
      # But neither must be in the first X characters.
      return false if semicolon && data.index(';') < 3
      return false if brace && data.index('}') < 4
    end
    token = data[0]
    case token
    when 's'
      if strict
        return false if data.slice(-2, 1) != '"'
      elsif !data.include?('"')
        return false
      end
      return data.match("^#{token}:[0-9]+:")
    when 'a', 'O'
      return data.match("^#{token}:[0-9]+:")
    when 'b', 'i', 'd'
      endd = strict ? '$' : ''
      return data.match("/^#{token}:[0-9.E-]+;#{endd}/")
    else
      return false
    end
  end


  # Test if a given filesystem path is absolute.
  #
  # For example, '/foo/bar', or 'c:\windows'.
  #
  # @param [string] path File path.
  # @return True if path is absolute, false is not absolute.
  def path_is_absolute(path)
    # Check to see if the path is a stream and check to see if its an actual
    # path or file as realpath() does not support stream wrappers.
    return true if (wp_is_stream(path) && (File.directory?(path) || File.file?(path)))

    # This is definitive if true but fails if $path does not exist or contains a symbolic link.
    require 'pathname'
    return true if Pathname.new(path).realpath.to_s == path

    return false if path.length == 0 || path[0] == '.'

    # Windows allows absolute paths like this.
    return true if path.match?(/^[a-zA-Z]:\\\\/)

    # A path starting with / or \ is absolute; anything else is relative.
    path[0] == '/' || path[0] == '\\'
  end

  # Join two filesystem paths together.
  #
  # For example, 'give me $path relative to $base'. If the $path is absolute,
  # then it the full path is returned.
  #
  # @param [string] base Base path.
  # @param [string] path Path relative to base.
  # @return string The path with the base or absolute path.
  def path_join(base, path)
    return path if path_is_absolute(path)
    base.gsub(/[\/]+$/, '') + '/' + path.gsub(/^[\/]+/, '')
  end


  # Retrieves uploads directory information.
  #
  # Same as wp_upload_dir() but "light weight" as it doesn't attempt to create the uploads directory.
  # Intended for use in themes, when only 'basedir' and 'baseurl' are needed, generally in all cases
  # when not uploading files.
  #
  # @return [array] See wp_upload_dir() for description.
  def wp_get_upload_dir
    wp_upload_dir(nil, false)
  end

  # Get an array containing the current upload directory's path and url.
  #
  # Checks the 'upload_path' option, which should be from the web root folder,
  # and if it isn't empty it will be used. If it is empty, then the path will be
  # 'WP_CONTENT_DIR/uploads'. If the 'UPLOADS' constant is defined, then it will
  # override the 'upload_path' option and 'WP_CONTENT_DIR/uploads' path.
  #
  # The upload URL path is set either by the 'upload_url_path' option or by using
  # the 'WP_CONTENT_URL' constant and appending '/uploads' to the path.
  #
  # If the 'uploads_use_yearmonth_folders' is set to true (checkbox if checked in
  # the administration settings panel), then the time will be used. The format
  # will be year first and then month.
  #
  # If the path couldn't be created, then an error will be returned with the key
  # 'error' containing the error message. The error suggests that the parent
  # directory is not writable by the server.
  #
  # On success, the returned array will have many indices:
  # 'path' - base directory and sub directory or full path to upload directory.
  # 'url' - base url and sub directory or absolute URL to upload directory.
  # 'subdir' - sub directory if uploads use year/month folders option is on.
  # 'basedir' - path without subdir.
  # 'baseurl' - URL path without subdir.
  # 'error' - false or error message.
  #
  # @uses _wp_upload_dir()
  #
  # @staticvar array $cache
  # @staticvar array $tested_paths
  #
  # @param [string] time Optional. Time formatted in 'yyyy/mm'. Default null.
  # @param [bool]   create_dir Optional. Whether to check and create the uploads directory.
  #                            Default true for backward compatibility.
  # @param [bool]   refresh_cache Optional. Whether to refresh the cache. Default false.
  # @return [array] See above for description.
  def wp_upload_dir(time = nil, create_dir = true, refresh_cache = false)
    # static $cache = array(), $tested_paths = array();
    #
    # key = sprintf( '%d-%s', get_current_blog_id(), time )
    #
    # if ( $refresh_cache || empty( $cache[ $key ] ) ) {
    #     $cache[ $key ] = _wp_upload_dir( $time );
    # }
    #
    # # Filters the uploads directory data.
    # $uploads = apply_filters( 'upload_dir', $cache[ $key ] );
    uploads = apply_filters('upload_dir', _wp_upload_dir(time))

    if create_dir # TS_INFO create dir not implemented
         path = uploads[:path]
    #
    # if ( array_key_exists( $path, $tested_paths ) ) {
    #     $uploads['error'] = $tested_paths[ $path ];
    # } else {
    #     if ( ! wp_mkdir_p( $path ) ) {
    #         if ( 0 === strpos( $uploads['basedir'], ABSPATH ) ) {
    #             $error_path = str_replace( ABSPATH, '', $uploads['basedir'] ) . $uploads['subdir'];
    #         } else {
    #             $error_path = wp_basename( $uploads['basedir'] ) . $uploads['subdir'];
    #         }
    #
    #         uploads[:error] = sprintf(
    #         __( 'Unable to create directory %s. Is its parent directory writable by the server?' ),
    #             esc_html( $error_path )
    #         );
    #     }
    #
    #     $tested_paths[ $path ] = $uploads['error'];
    # }
    end

    uploads
  end


  # A non-filtered, non-cached version of wp_upload_dir() that doesn't check the path.
  #
  # @access private
  #
  # @param [string] time Optional. Time formatted in 'yyyy/mm'. Default null.
  # @return [array] See wp_upload_dir()
  def _wp_upload_dir(time = nil)
    siteurl = get_option('siteurl')
    upload_path = get_option('upload_path', '').strip

    if upload_path.blank? || 'wp-content/uploads' == upload_path
      dir = Railspress.WP_CONTENT_DIR + '/uploads'
    elsif upload_path.include? Railspress.ABSPATH
      # $dir is absolute, $upload_path is (maybe) relative to ABSPATH
      dir = path_join(Railspress.ABSPATH, upload_path)
    else
      dir = upload_path
    end

    url = get_option( 'upload_url_path' )
    unless url == false
      if upload_path.blank? || 'wp-content/uploads' == upload_path || upload_path == dir
        url = Railspress.WP_CONTENT_URL + '/uploads'
      else
        url = trailingslashit( siteurl ) + upload_path
      end
    end

    # Honor the value of UPLOADS. This happens as long as ms-files rewriting is disabled.
    # We also sometimes obey UPLOADS when rewriting is enabled -- see the next block.
    if defined?(Railspress.UPLOADS) && !Railspress.UPLOADS.nil? && ! ( is_multisite && get_site_option( 'ms_files_rewriting' ) )
      dir = Railspress.ABSPATH + Railspress.UPLOADS
      url = trailingslashit(siteurl) + Railspress.UPLOADS
    end

    # If multisite (and if not the main site in a post-MU network)
    # if is_multisite && ! ( is_main_network() && is_main_site() && defined( 'MULTISITE' ) )
    #   # TS_INFO: multisite not implemented
    # end

    basedir = dir
    baseurl = url

    subdir = ''
    if get_option('uploads_use_yearmonth_folders') == '1'
      # Generate the yearly and monthly dirs
      time = current_time('mysql') if time.nil?
      y      = time[0, 4]
      m      = time[5, 2]
      subdir = "/#{y}/#{m}"
    end

    dir += subdir
    url += subdir

    {
        path:     dir,
        url:      url,
        subdir:   subdir,
        basedir:  basedir,
        baseurl:  baseurl,
        error:    false,
    }
  end


  # Retrieve the file type from the file name.
  #
  # You can optionally define the mime array, if needed.
  #
  # @param [String] filename File name or path.
  # @param [Array]  mimes    Optional. Key is the file extension with value as the mime type.
  # @return [Array] Values with extension first and mime type.
  def wp_check_filetype(filename, mimes = nil)
    mimes = get_allowed_mime_types if mimes.blank?
    result = {
        ext: false,
        type: false
    }
    mimes.each_pair do |ext_preg, mime_match|
      ext_preg = '!\.(' + ext_preg + ')$!i'
      ext_matches = ext_preg.match filename # (preg_match(ext_preg, filename, ext_matches))
      if ext_matches
        result[:type] = mime_match
        result[:ext] = ext_matches[1]
        break
      end
    end
    result
  end

  # Retrieve list of mime types and file extensions.
  #
  # @return Array of mime types keyed by the file extension regex corresponding to those types.
  def wp_get_mime_types
    # Filters the list of mime types and file extensions.
    apply_filters(
        'mime_types',
        {
            # Image formats.
            'jpg|jpeg|jpe':                  'image/jpeg',
            'gif':                           'image/gif',
            'png':                           'image/png',
            'bmp':                           'image/bmp',
            'tiff|tif':                      'image/tiff',
            'ico':                           'image/x-icon',
            # Video formats.
            'asf|asx':                       'video/x-ms-asf',
            'wmv':                           'video/x-ms-wmv',
            'wmx':                           'video/x-ms-wmx',
            'wm':                            'video/x-ms-wm',
            'avi':                           'video/avi',
            'divx':                          'video/divx',
            'flv':                           'video/x-flv',
            'mov|qt':                        'video/quicktime',
            'mpeg|mpg|mpe':                  'video/mpeg',
            'mp4|m4v':                       'video/mp4',
            'ogv':                           'video/ogg',
            'webm':                          'video/webm',
            'mkv':                           'video/x-matroska',
            '3gp|3gpp':                      'video/3gpp', # Can also be audio
            '3g2|3gp2':                      'video/3gpp2', # Can also be audio
            # Text formats.
            'txt|asc|c|cc|h|srt':            'text/plain',
            'csv':                           'text/csv',
            'tsv':                           'text/tab-separated-values',
            'ics':                           'text/calendar',
            'rtx':                           'text/richtext',
            'css':                           'text/css',
            'htm|html':                      'text/html',
            'vtt':                           'text/vtt',
            'dfxp':                          'application/ttaf+xml',
            # Audio formats.
            'mp3|m4a|m4b':                   'audio/mpeg',
            'aac':                           'audio/aac',
            'ra|ram':                        'audio/x-realaudio',
            'wav':                           'audio/wav',
            'ogg|oga':                       'audio/ogg',
            'flac':                          'audio/flac',
            'mid|midi':                      'audio/midi',
            'wma':                           'audio/x-ms-wma',
            'wax':                           'audio/x-ms-wax',
            'mka':                           'audio/x-matroska',
            # Misc application formats.
            'rtf':                           'application/rtf',
            'js':                            'application/javascript',
            'pdf':                           'application/pdf',
            'swf':                           'application/x-shockwave-flash',
            'class':                         'application/java',
            'tar':                           'application/x-tar',
            'zip':                           'application/zip',
            'gz|gzip':                       'application/x-gzip',
            'rar':                           'application/rar',
            '7z':                            'application/x-7z-compressed',
            'exe':                           'application/x-msdownload',
            'psd':                           'application/octet-stream',
            'xcf':                           'application/octet-stream',
            # MS Office formats.
            'doc':                           'application/msword',
            'pot|pps|ppt':                   'application/vnd.ms-powerpoint',
            'wri':                           'application/vnd.ms-write',
            'xla|xls|xlt|xlw':               'application/vnd.ms-excel',
            'mdb':                           'application/vnd.ms-access',
            'mpp':                           'application/vnd.ms-project',
            'docx':                          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'docm':                          'application/vnd.ms-word.document.macroEnabled.12',
            'dotx':                          'application/vnd.openxmlformats-officedocument.wordprocessingml.template',
            'dotm':                          'application/vnd.ms-word.template.macroEnabled.12',
            'xlsx':                          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'xlsm':                          'application/vnd.ms-excel.sheet.macroEnabled.12',
            'xlsb':                          'application/vnd.ms-excel.sheet.binary.macroEnabled.12',
            'xltx':                          'application/vnd.openxmlformats-officedocument.spreadsheetml.template',
            'xltm':                          'application/vnd.ms-excel.template.macroEnabled.12',
            'xlam':                          'application/vnd.ms-excel.addin.macroEnabled.12',
            'pptx':                          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
            'pptm':                          'application/vnd.ms-powerpoint.presentation.macroEnabled.12',
            'ppsx':                          'application/vnd.openxmlformats-officedocument.presentationml.slideshow',
            'ppsm':                          'application/vnd.ms-powerpoint.slideshow.macroEnabled.12',
            'potx':                          'application/vnd.openxmlformats-officedocument.presentationml.template',
            'potm':                          'application/vnd.ms-powerpoint.template.macroEnabled.12',
            'ppam':                          'application/vnd.ms-powerpoint.addin.macroEnabled.12',
            'sldx':                          'application/vnd.openxmlformats-officedocument.presentationml.slide',
            'sldm':                          'application/vnd.ms-powerpoint.slide.macroEnabled.12',
            'onetoc|onetoc2|onetmp|onepkg':  'application/onenote',
            'oxps':                          'application/oxps',
            'xps':                           'application/vnd.ms-xpsdocument',
            # OpenOffice formats.
            'odt':                           'application/vnd.oasis.opendocument.text',
            'odp':                           'application/vnd.oasis.opendocument.presentation',
            'ods':                           'application/vnd.oasis.opendocument.spreadsheet',
            'odg':                           'application/vnd.oasis.opendocument.graphics',
            'odc':                           'application/vnd.oasis.opendocument.chart',
            'odb':                           'application/vnd.oasis.opendocument.database',
            'odf':                           'application/vnd.oasis.opendocument.formula',
            # WordPerfect formats.
            'wp|wpd':                        'application/wordperfect',
            # iWork formats.
            'key':                           'application/vnd.apple.keynote',
            'numbers':                       'application/vnd.apple.numbers',
            'pages':                         'application/vnd.apple.pages',
        }
    )
  end

  # Retrieve list of allowed mime types and file extensions.
  # @param [int|WP_User] user Optional. User to check. Defaults to current user.
  # @return Array of mime types keyed by the file extension regex corresponding to those types.
  def get_allowed_mime_types(user = nil)
    t = wp_get_mime_types
    t.delete(:swf)
    t.delete(:exe)
    # TODO implement:
    # if ( function_exists( 'current_user_can' ) )
    #     unfiltered = user ? user_can( user, 'unfiltered_html' ) : current_user_can( 'unfiltered_html' )
    # end
    # if unfiltered.blank?
    #   t.delete(:'htm|html')
    #   t.delete(:js)
    # end

    # Filters list of allowed mime types and file extensions.
    apply_filters('upload_mimes', t, user)
  end

  # Merge user defined arguments into defaults array.
  #
  # This function is used throughout WordPress to allow for both string or array to be merged into another array.
  #
  # @param [string|array|object] args     Value to merge with $defaults.
  # @param [array]               defaults Optional. Array that serves as the defaults. Default empty.
  # @return [array] Merged user defined values with defaults.
  def self.wp_parse_args(args, defaults = '')
    require_relative '../../app/helpers/railspress/formatting_helper'
    # TODO if ( is_object( args ) )
    #     $r = get_object_vars( $args );
    #  els
    if args.kind_of? Hash
      r = args
    else
      r = Railspress::FormattingHelper.wp_parse_str(args)
    end

    if defaults.kind_of? Hash
      return defaults.merge(r || {})
    end
    return r
  end

  # Cleans up an array, comma- or space-separated list of scalar values.
  #
  # @param [array|string] list List of values.
  # @return Sanitized array of values.
  def wp_parse_list(list)
    return list if list.kind_of?(Array)
    list.split(/[\s,]+/)
  end

  # Clean up an array, comma- or space-separated list of IDs.
  #
  # @param [array|string] list List of ids.
  # @return Sanitized array of IDs.
  def wp_parse_id_list(list)
    list = wp_parse_list list
    list.map{|i| i.to_i.abs}.uniq
  end

  # Filters a list of objects, based on a set of key => value arguments.
  #
  # @since 3.0.0
  # @since 4.7.0 Uses `WP_List_Util` class.
  #
  # @param [array]       list     An array of objects to filter
  # @param [array]       args     Optional. An array of key => value arguments to match
  #                               against each object. Default empty array.
  # @param [string]      operator Optional. The logical operation to perform. 'or' means
  #                               only one element from the array needs to match; 'and'
  #                               means all elements must match; 'not' means no elements may
  #                               match. Default 'and'.
  # @param [bool|string] field    A field from the object to place instead of the entire object.
  #                               Default false.
  # @return [array] A list of objects or object fields.
  def wp_filter_object_list(list, args = {}, operator = 'and', field = false)
    return {} unless list.is_a? Hash

    util = Railspress::WP_List_Util.new(list)
    util.filter(args, operator)
    util.pluck(field) if field
    util.output
  end


  # Whether to force SSL used for the Administration Screens.
  #
  # @param [string|bool] $force Optional. Whether to force SSL in admin screens. Default null.
  # @return [bool] True if forced, false if not forced.
  def force_ssl_admin(force = nil)
    # TS_INFO: true always
    #	static forced = false
    #
    #	unless force.nil?
    #		old_forced = forced
    #		forced     = force
    #		return old_forced
    #	end
    #
    #	forced
    true
  end


  # Retrieve a list of protocols to allow in HTML attributes.
  #
  # @see wp_kses()
  # @see esc_url()
  #
  # @staticvar array $protocols
  #
  # @return Array of allowed protocols. Defaults to an array containing 'http', 'https',
  #                  'ftp', 'ftps', 'mailto', 'news', 'irc', 'gopher', 'nntp', 'feed', 'telnet',
  #                  'mms', 'rtsp', 'svn', 'tel', 'fax', 'xmpp', 'webcal', and 'urn'. This covers
  #                  all common link protocols, except for 'javascript' which should not be
  #                  allowed for untrusted users.
  def wp_allowed_protocols
    # TODO static $
    protocols = []

    if protocols.empty?
      protocols = [ 'http', 'https', 'ftp', 'ftps', 'mailto', 'news', 'irc', 'gopher', 'nntp', 'feed', 'telnet', 'mms', 'rtsp', 'svn', 'tel', 'fax', 'xmpp', 'webcal', 'urn' ]
    end

    # TODO ? if ( ! did_action( 'wp_loaded' ) ) {
    # 	# Filters the list of protocols allowed in HTML attributes.
    # 	$protocols = array_unique( (array) apply_filters( 'kses_allowed_protocols', $protocols ) );
    # }

    protocols
  end


  # Test if a given path is a stream URL
  # @param [String] path The resource path or URL.
  # @return True if the path is a stream URL.
  def wp_is_stream( path )
    return false unless path.include?('://') # path isn't a stream

    scheme_separator = path.index('://')

    stream = path.slice(0, scheme_separator)
    stream_get_wrappers.include? stream
  end

  # This is from PHP
  def stream_get_wrappers
    %w(https ftps compress.zlib php file glob data http ftp phar)
  end
end