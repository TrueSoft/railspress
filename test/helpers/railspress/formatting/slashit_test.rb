require 'test_helper'

class SlashitTest < ActionView::TestCase
  include Railspress::FormattingHelper

  # TODO 3 backslashit tests

  test "removes trailing slashes" do
    assert_equal 'a', untrailingslashit('a/')
    assert_equal 'a', untrailingslashit('a////')
  end

  test "removes trailing backslashes" do
    assert_equal 'a', untrailingslashit('a\\')
    assert_equal 'a', untrailingslashit('a\\\\\\\\')
  end

  test "removes trailing mixed slashes" do
    assert_equal 'a', untrailingslashit( 'a/\\' )
    assert_equal 'a', untrailingslashit( 'a\\/\\///\\\\//' )
  end

  test "adds trailing slash" do
    assert_equal 'a/', trailingslashit( 'a' )
  end

  test "does not add trailing slash if one exists" do
    assert_equal 'a/', trailingslashit( 'a/' )
  end

  test "converts trailing backslash to slash if one exists" do
    assert_equal 'a/', trailingslashit( 'a\\' )
  end

end