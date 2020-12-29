require 'test_helper'

class UrlTest < ActionView::TestCase
  include Railspress::OptionsHelper
  include Railspress::Plugin
  include Railspress::LinkTemplateHelper
  include Railspress::Load

  def tst_home_url(url, expected)
    homeurl_http = get_option('home')
    # home_url_http = home_url( url )

    # $_SERVER['HTTPS'] = 'on';

    homeurl_https = set_url_scheme(homeurl_http, 'https')
    home_url_https = home_url(url)

    # assert_equal( homeurl_http + expected, home_url_http )
    assert_equal(homeurl_https + expected, home_url_https)
  end

  test "home urls" do
    tst_home_url nil, ''
    tst_home_url 0, ''
    tst_home_url -1, ''
    # tst_home_url '///', '/'
    tst_home_url '', ''
    tst_home_url 'foo', '/foo'
    tst_home_url '/foo', '/foo'
    tst_home_url '/foo/', '/foo/'
    tst_home_url 'foo.php', '/foo.php'
    tst_home_url '/foo.php', '/foo.php'
    tst_home_url '/foo.php?bar=1', '/foo.php?bar=1'
  end

  test "get adjacent post" do
    # $now      = time();
    # $post_id  = self::factory()->post->create( array( 'post_date' => gmdate( 'Y-m-d H:i:s', $now - 1 ) ) );
    # $post_id2 = self::factory()->post->create( array( 'post_date' => gmdate( 'Y-m-d H:i:s', $now ) ) );
    #
    # if ( ! isset( $GLOBALS['post'] ) ) {
    #   $GLOBALS['post'] = null;
    # }
    # $orig_post       = $GLOBALS['post'];
    # $GLOBALS['post'] = get_post( $post_id2 );
    #
    # $p = get_adjacent_post();
    # $this->assertInstanceOf( 'WP_Post', $p );
    # $this->assertEquals( $post_id, $p->ID );
    #
    # // The same again to make sure a cached query returns the same result
    # $p = get_adjacent_post();
    # $this->assertInstanceOf( 'WP_Post', $p );
    # $this->assertEquals( $post_id, $p->ID );
    #
    # // Test next
    # $p = get_adjacent_post( false, '', false );
    # $this->assertEquals( '', $p );
    #
    # unset( $GLOBALS['post'] );
    # $this->assertNull( get_adjacent_post() );
    #
    # $GLOBALS['post'] = $orig_post;
  end

  # Test that *_url functions handle paths with ".."
  #
  # @ticket 19032
  test "url functions for dots in paths" do
    functions = [
      :site_url,
      :home_url,
      :admin_url,
      # :network_admin_url,
      # :user_admin_url,
      :includes_url,
      # :network_site_url,
      # :network_home_url,
      :content_url,
      # :plugins_url,
    ]
    functions.each { |function|
      assert_equal send(function, '/') + '../', send(function, '../')
      assert_equal send(function, '/') + 'something...here', send(function, 'something...here')
    }
    # These functions accept a blog ID argument.
    [:get_site_url, :get_home_url, :get_admin_url].each { |function|
      assert_equal send(function, nil, '/') + '../', send(function, nil, '../')
      assert_equal send(function, nil, '/') + 'something...here', send(function, nil, 'something...here')
    }
  end

end