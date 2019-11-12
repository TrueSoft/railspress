=begin
 * Core Metadata API
 *
 * Functions for retrieving and manipulating metadata of various WordPress object types. Metadata
 * for an object is a represented by a simple key-value pair. Objects may contain multiple
 * metadata entries that share the same key and differ only in their value.
 *
 * file wp-includes\meta.php
=end
module Railspress::MetaHelper

  require 'php_serialization'

  # Retrieve metadata for the specified object.
  # @param meta_type Type of object metadata is for (e.g., comment, post, term, or user).
  # @param object_id ID of the object metadata is for
  # @param meta_key  Optional. Metadata key. If not specified, retrieve all metadata for the specified object.
  # @param single    Optional, default is false.
  #                            If true, return only the first value of the specified meta_key.
  #                            This parameter has no effect if meta_key is not specified.
  # @return Single metadata value, or array of values
  def get_metadata(meta_type, object_id, meta_key = '', single = false)
    return false if meta_type.nil? or !object_id.is_a?(Integer)
    # Filters whether to retrieve metadata of a specific type.
    check = apply_filters("get_#{meta_type}_metadata", nil, object_id, meta_key, single)
    unless check.nil?
      if single && check.kind_of?(Array)
        return check[0]
      else
        return check
      end
    end
    # meta_cache = wp_cache_get( object_id, meta_type + '_meta' )
    values = Railspress::Postmeta.where(post_id: object_id, meta_key: meta_key).pluck(:meta_value)
    values.map! {|meta_value| maybe_unserialize meta_value }
    if values.blank?
      single ? '' : []
    else
      single ? values[0] : values
    end
  end


end