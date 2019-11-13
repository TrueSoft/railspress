=begin
 * WordPress DB Class
 *
 * file wp-includes\wp-db.php
=end
module Railspress::WpDbHelper

# Real escape, using mysqli_real_escape_string() or mysql_real_escape_string()
#
# @see mysqli_real_escape_string()
# @see mysql_real_escape_string()
# @since 2.8.0
#
# @param  string $string to escape
# @return string escaped
  def _real_escape(string)
    string
    # TODO implement wp-db.php _real_escape()
    #     if ( $this->dbh ) {
    #     if ( $this->use_mysqli ) {
    #         $escaped = mysqli_real_escape_string( $this->dbh, $string );
    #     } else {
    #         $escaped = mysql_real_escape_string( $string, $this->dbh );
    #     }
    #     } else {
    #         $class = get_class( $this );
    #     if ( function_exists( '__' ) ) {
    #         /* translators: %s: database access abstraction class, usually wpdb or a class extending wpdb */
    #     _doing_it_wrong( $class, sprintf( __( '%s must set a database connection for use with escaping.' ), $class ), '3.6.0' );
    #     } else {
    #         _doing_it_wrong( $class, sprintf( '%s must set a database connection for use with escaping.', $class ), '3.6.0' );
    #     }
    #     escaped = addslashes( string )
    #     }
    #
    #    add_placeholder_escape( escaped )
  end

  # Escape data. Works on arrays.
  #
  # @uses wpdb::_real_escape()
  #
  # @param  [string|array] data
  # @return [string|array] escaped
  def _escape( data )
    if data.is_a? Array
      data.map! { |v|
        if v.is_a? Array
          _escape v
        else
          _real_escape v
        end
      }
    else
      data = _real_escape(data)
    end

    data
  end

end