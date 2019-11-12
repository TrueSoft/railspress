=begin
 * Option API
 *
 * file wp-includes\option.php
=end
module Railspress::OptionsHelper

  def option_is_editable_ts(option_name)
    return true if EDITABLE_OPTIONS.include?(option_name.to_s)
    editable_simple = []#Rails.configuration.TS_EDITABLE_OPTIONS.reject {|on| on.index('*')}
    editable_wildcards = []#Rails.configuration.TS_EDITABLE_OPTIONS.select {|on| on.index('*')}
    return true if editable_simple.include?(option_name.to_s)
    editable_wildcards.each do |opt_name|
      return true if option_name.to_s =~ Regexp.new(opt_name.gsub(/\*/, '.*'))
    end
    return false
  end

  def option_is_deletable_ts(option_name)
    editable_simple = []#Rails.configuration.TS_EDITABLE_OPTIONS.reject {|on| on.index('*')}
    editable_wildcards = []#Rails.configuration.TS_EDITABLE_OPTIONS.select {|on| on.index('*')}
    return true if editable_simple.include?(option_name.to_s)
    editable_wildcards.each do |opt_name|
      return true if option_name.to_s =~ Regexp.new(opt_name.gsub(/\*/, '.*'))
    end
    return false
  end

  # Retrieves an option value based on an option name.
  # @param [string] option  Name of option to retrieve. Expected to not be SQL-escaped.
  # @param [mixed]  default Optional. Default value to return if the option does not exist.
  # @return [mixed] Value set for the option.
  def get_option(option, default = (default_not_passed = true; false))
    # global $wpdb;
    option = option.strip
    return false if option.blank?
    # Filters the value of an existing option before it is retrieved.
    pre = apply_filters("pre_option_#{option}", false, option, default)

    return pre if pre != false
    return false if defined? WP_SETUP_CONFIG
    passed_default = !default_not_passed
    if true #! wp_installing()
      value = Railspress::Option.where(option_name: option).pluck(:option_value).first
      if value.nil?
        return apply_filters( "default_option_#{option}", default, option, passed_default)
      else
        return apply_filters( "option_#{option}", maybe_unserialize(value), option)
      end
      # prevent non-existent options from triggering multiple queries
      notoptions = wp_cache_get( 'notoptions', 'options' )
      if ( isset( $notoptions[ $option ] ) )
        # Filters the default value for an option.
        return apply_filters( "default_option_#{option}", default, option, passed_default)
      end

      alloptions = wp_load_alloptions()

      if alloptions[option]
        value = alloptions[option]
      else
        value = wp_cache_get(option, 'options')
# TODO continue implement option.php
        if false == value
          $row = $wpdb.get_row( $wpdb.prepare( "SELECT option_value FROM $wpdb->options WHERE option_name = %s LIMIT 1", option ) )

          # Has to be get_row instead of get_var because of funkiness with 0, false, null values
          if is_object( $row )
            value = $row.option_value
            wp_cache_add(option, value, 'options')
          else  # option does not exist, so we must cache its non-existence
            if !notoptions.kind_of?(Hash)
              notoptions = {};
            end
            notoptions[ option ] = true
            wp_cache_set( 'notoptions', notoptions, 'options' )

            # This filter is documented in wp-includes/option.php */
            return apply_filters("default_option_#{option}", default, option, passed_default)
          end
        end
      end
    else
      # not implementing this case
    end
    # If home is not set use siteurl.
    if 'home' == option && '' == value
      return get_option('siteurl')
    end

    if ['siteurl', 'home', 'category_base', 'tag_base'].include? option
      value = untrailingslashit(value)
    end

    # Filters the value of an existing option.
    apply_filters( "option_#{option}", maybe_unserialize(value), option)
  end


end
