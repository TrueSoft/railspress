=begin
 # These functions are needed to load WordPress.
 *
 * file wp-includes\load.php
=end
module Railspress::Load

  # Determines whether the current request is for an administrative interface page.
  #
  # Does not check if the user is an administrator; use current_user_can()
  # for checking roles and capabilities.
  #
  # For more information on this and similar theme functions, check out
  # the {@link https://developer.wordpress.org/themes/basics/conditional-tags/
  # Conditional Tags} article in the Theme Developer Handbook.
  #
  # @since 1.5.1
  #
  # @global WP_Screen $current_screen
  #
  # @return bool True if inside WordPress administration interface, false otherwise.
  def is_admin
    # TS_INFO: Admin interface not implemented
    # if isset( $GLOBALS['current_screen'] ) )
    # return $GLOBALS['current_screen']->in_admin()
    # elsif ( defined( 'WP_ADMIN' ) )
    #   return WP_ADMIN
    # end
    false
  end

  # If Multisite is enabled.
  #
  # @return bool True if Multisite is enabled, false otherwise.
  def is_multisite
    # TS_INFO: Multisite not implemented
    #	if ( defined( 'MULTISITE' ) ) {
    #		return MULTISITE;
    #	}
    #
    #	if ( defined( 'SUBDOMAIN_INSTALL' ) || defined( 'VHOST' ) || defined( 'SUNRISE' ) ) {
    #		return true;
    #	}
    false
  end

  # Determines if SSL is used.
  #
  # @return bool True if SSL, otherwise false.
  def is_ssl
    # TS_INFO: Returns true always
    #    if ( isset( $_SERVER['HTTPS'] ) ) {
    #        if ( 'on' == strtolower( $_SERVER['HTTPS'] ) ) {
    #            return true;
    #        }
    #
    #        if ( '1' == $_SERVER['HTTPS'] ) {
    #            return true;
    #        }
    #    } elseif ( isset( $_SERVER['SERVER_PORT'] ) && ( '443' == $_SERVER['SERVER_PORT'] ) ) {
    #        return true;
    #    }
    #    return false;
    true
  end
end