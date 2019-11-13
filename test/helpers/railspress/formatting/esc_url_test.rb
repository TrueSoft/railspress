require 'test_helper'

class EscUrlTest < ActionView::TestCase
  include Railspress::FormattingHelper
  include Railspress::Functions
  include Railspress::KsesHelper
  include Railspress::Plugin

  test "spaces" do
    assert_equal 'http://example.com/Mr%20WordPress', esc_url('http://example.com/Mr WordPress')
    assert_equal 'http://example.com/Mr%20WordPress', esc_url('http://example.com/Mr%20WordPress')
    assert_equal 'http://example.com/Mr%20%20WordPress', esc_url('http://example.com/Mr%20%20WordPress')
    assert_equal 'http://example.com/Mr+WordPress', esc_url('http://example.com/Mr+WordPress')

    assert_equal 'http://example.com/?foo=one%20two%20three&#038;bar=four', esc_url('http://example.com/?foo=one two three&bar=four')
    assert_equal 'http://example.com/?foo=one%20two%20three&#038;bar=four', esc_url('http://example.com/?foo=one%20two%20three&bar=four')
  end

  # test "bad characters" do
  #   # skip "Not working yet"
  #   assert_equal 'http://example.com/watchthelinefeedgo', esc_url( 'http://example.com/watchthelinefeed%0Ago' )
  #   assert_equal 'http://example.com/watchthelinefeedgo', esc_url( 'http://example.com/watchthelinefeed%0ago' )
  #   assert_equal 'http://example.com/watchthecarriagereturngo', esc_url( 'http://example.com/watchthecarriagereturn%0Dgo' )
  #   assert_equal 'http://example.com/watchthecarriagereturngo', esc_url( 'http://example.com/watchthecarriagereturn%0dgo' )
  #   # Nesting Checks
  #   assert_equal 'http://example.com/watchthecarriagereturngo', esc_url( 'http://example.com/watchthecarriagereturn%0%0ddgo' )
  #   assert_equal 'http://example.com/watchthecarriagereturngo', esc_url( 'http://example.com/watchthecarriagereturn%0%0DDgo' )
  #   assert_equal 'http://example.com/', esc_url( 'http://example.com/%0%0%0DAD' )
  #   assert_equal 'http://example.com/', esc_url( 'http://example.com/%0%0%0ADA' )
  #   assert_equal 'http://example.com/', esc_url( 'http://example.com/%0%0%0DAd' )
  #   assert_equal 'http://example.com/', esc_url( 'http://example.com/%0%0%0ADa' )
  # end

  test "relative" do
    assert_equal '/example.php', esc_url( '/example.php' )
    assert_equal 'example.php', esc_url( 'example.php' )
    assert_equal '#fragment', esc_url( '#fragment' )
    assert_equal '?foo=bar', esc_url( '?foo=bar' )
  end

  # TODO test_all_url_parts

  test "bare" do
    assert_equal 'http://example.com?foo', esc_url( 'example.com?foo' )
    assert_equal 'http://example.com', esc_url( 'example.com' )
    assert_equal 'http://localhost', esc_url( 'localhost' )
    assert_equal 'http://example.com/foo', esc_url( 'example.com/foo' )
  # TODO  assert_equal 'http://баба.org/баба', esc_url( 'баба.org/баба' )
  end

  # TODO tests from esc_url

  # test "invalid characters" do
  #   assert_empty esc_url_raw('"^<>{}`')
  # end

  # test "ipv6_hosts" do
  #   assert_equal '//[::127.0.0.1]', esc_url( '//[::127.0.0.1]' )
  #   assert_equal 'http://[::FFFF::127.0.0.1]', esc_url( 'http://[::FFFF::127.0.0.1]' )
  #   assert_equal 'http://[::127.0.0.1]', esc_url( 'http://[::127.0.0.1]' )
  #   assert_equal 'http://[::DEAD:BEEF:DEAD:BEEF:DEAD:BEEF:DEAD:BEEF]', esc_url( 'http://[::DEAD:BEEF:DEAD:BEEF:DEAD:BEEF:DEAD:BEEF]' )
  #
  #   # IPv6 with square brackets in the query? Why not.
  #   assert_equal '//[::FFFF::127.0.0.1]/?foo%5Bbar%5D=baz', esc_url( '//[::FFFF::127.0.0.1]/?foo[bar]=baz' )
  #   assert_equal 'http://[::FFFF::127.0.0.1]/?foo%5Bbar%5D=baz', esc_url( 'http://[::FFFF::127.0.0.1]/?foo[bar]=baz' )
  # end


end
