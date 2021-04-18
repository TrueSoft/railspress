=begin
 * Option API
 *
 * file wp-includes\option.php
=end
module Railspress::OptionsHelper

  def option_is_editable_ts(option_name)
    return true if EDITABLE_OPTIONS.include?(option_name.to_s)
    editable_simple = Railspress.TS_EDITABLE_OPTIONS.reject {|on| on.index('*')}
    editable_wildcards = Railspress.TS_EDITABLE_OPTIONS.select {|on| on.index('*')}
    return true if editable_simple.include?(option_name.to_s)
    editable_wildcards.each do |opt_name|
      return true if option_name.to_s =~ Regexp.new(opt_name.gsub(/\*/, '.*'))
    end
    return false
  end

  def option_is_deletable_ts(option_name)
    editable_simple = Railspress.TS_EDITABLE_OPTIONS.reject {|on| on.index('*')}
    editable_wildcards = Railspress.TS_EDITABLE_OPTIONS.select {|on| on.index('*')}
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
    option = option.strip
    return false if option.blank?
    # Filters the value of an existing option before it is retrieved.
    pre = apply_filters("pre_option_#{option}", false, option, default)

    return pre if pre != false
    # return false if defined? WP_SETUP_CONFIG
    passed_default = !default_not_passed
    if true #! wp_installing()
      # prevent non-existent options from triggering multiple queries
      notoptions = Rails.cache.read 'Railspress::' + 'options' + '/' + 'notoptions'
      if !notoptions.blank? && notoptions[option]
        # Filters the default value for an option.
        return apply_filters( "default_option_#{option}", default, option, passed_default)
      end

      alloptions = wp_load_alloptions

      if alloptions[option]
        value = alloptions[option]
      else
        value = Rails.cache.fetch('Railspress::' + 'options' + '/' + option) {
          Railspress::Option.where(option_name: option).pluck(:option_value).first
        }
        if value.nil?  # option does not exist, so we must cache its non-existence
          notoptions = {} unless notoptions.kind_of? Hash
          notoptions[ option ] = true
          Rails.cache.write 'Railspress::' + 'options' + '/' + 'notoptions', notoptions
          # This filter is documented in wp-includes/option.php */
          return apply_filters("default_option_#{option}", default, option, passed_default)
        end
      end
    else
      # not implementing this case
    end
    # If home is not set use siteurl.
    if 'home' == option && '' == value
      return get_option('siteurl')
    end

    if %w(siteurl home category_base tag_base).include? option
      value = Railspress::FormattingHelper.untrailingslashit(value)
    end

    # Filters the value of an existing option.
    apply_filters( "option_#{option}", Railspress::Functions.maybe_unserialize(value), option).freeze
  end

  # Protect WordPress special option from being modified.
  #
  # Will die if $option is in protected list. Protected options are 'alloptions'
  # and 'notoptions' options.
  #
  # @param [string] option Option name.
  def wp_protect_special_option( option )
    if 'alloptions' == option || 'notoptions' == option
      raise sprintf( '%s is a protected WP option and may not be modified', esc_html(option))
    end
  end

  # Loads and caches all autoloaded options, if available or all options.
  #
  # @return array List of all options.
  def wp_load_alloptions
    if true # ! wp_installing() || ! is_multisite()
      alloptions = false # TS_INFO:  don't save all in cache wp_cache_get( 'alloptions', 'options' )
    else
      alloptions = false
    end

    unless alloptions
      alloptions = {}
      # TS_INFO: Don't load all in the cache
      # foreach ( (array) $alloptions_db as $o ) {
      #     $alloptions[ $o->option_name ] = $o->option_value;
      # }
      #
      # if ( ! wp_installing() || ! is_multisite() )
      #     # Filters all options before caching them.
      #     alloptions = apply_filters( 'pre_cache_alloptions', alloptions )
      #     wp_cache_add( 'alloptions', alloptions, 'options' )
      # end
    end

    # Filters all options after retrieving them.
    apply_filters( 'alloptions', alloptions )
  end

  def update_option_to_db(option, value, autoload = nil)
    option_obj = Railspress::Option.where(option_name: option).first
    if option_obj.nil?
      option_obj = Railspress::Option.new(option_name: option, option_value: value, autoload: autoload == 'yes' ? 'yes' : 'no')
      option_obj.save
    elsif option_obj.option_value != value
      option_obj.update_attribute(:option_value, value)
    else
      false # no change
    end
  end

  def update_option(option, value, autoload = nil)
    option = option.strip
    return false if option.blank?

    wp_protect_special_option( option )

    # value     = sanitize_option( option, value )
    old_value = get_option( option )

    # Filters a specific option before its value is (maybe) serialized and updated.
    #
    # The dynamic portion of the hook name, `$option`, refers to the option name.
    #
    # @param mixed  $value     The new, unserialized option value.
    # @param mixed  $old_value The old option value.
    # @param string $option    Option name.
    value = apply_filters( "pre_update_option_{$option}", value, old_value, option )

    # Filters an option before its value is (maybe) serialized and updated.
    #
    # @param mixed  $value     The new, unserialized option value.
    # @param string $option    Name of the option.
    # @param mixed  $old_value The old option value.
    value = apply_filters( 'pre_update_option', value, option, old_value )

    # If the new and old values are the same, no need to update.
    #
    # Unserialized values will be adequate in most cases. If the unserialized
    # data differs, the (maybe) serialized data is checked to avoid
    # unnecessary database calls for otherwise identical object instances.
    #
    # See https://core.trac.wordpress.org/ticket/38903
    if value == old_value # || maybe_serialize( value ) == maybe_serialize( old_value )
      return false
    end

    Rails.cache.write 'Railspress::' + 'options' + '/' + option, value

    notoptions = Rails.cache.read 'Railspress::' + 'options' + '/' + 'notoptions'
    if !notoptions.blank? && notoptions[option]
      notoptions.delete option
      Rails.cache.write 'Railspress::' + 'options' + '/' + 'notoptions', notoptions
    end

    # Fires after the value of a specific option has been successfully updated.
    do_action( "update_option_#{option}", old_value, value, option )

    # Fires after the value of an option has been successfully updated.
    do_action( 'updated_option', option, old_value, value )
    true
  end

  def add_option(option, value = '', deprecated = '', autoload = 'yes')
    option = option.strip
    return false if option.blank?

    wp_protect_special_option( option )

    Rails.cache.write 'Railspress::' + 'options' + '/' + option, value

    notoptions = Rails.cache.read 'Railspress::' + 'options' + '/' + 'notoptions'
    if !notoptions.blank? && notoptions[option]
      notoptions.delete option
      Rails.cache.write 'Railspress::' + 'options' + '/' + 'notoptions', notoptions
    end

    true
  end

  # Removes option by name. Prevents removal of protected WordPress options.
  #
  # @param [string] option Name of option to remove. Expected to not be SQL-escaped.
  # @return bool True, if option is successfully deleted. False on failure.
  def delete_option( option )
    option = option.strip
    return false if option.blank?

    wp_protect_special_option( option )

    Rails.cache.delete 'Railspress::' + 'options' + '/' + option
    true
  end

end
