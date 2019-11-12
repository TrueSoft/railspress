require 'test_helper'

class EscAttrTest < ActionView::TestCase
  include Railspress::FormattingHelper
  include Railspress::OptionsHelper
  include Railspress::Plugin
  include CGI::Util

  test "esc attr quotes" do
    attr = '"double quotes"'
    assert_equal '&quot;double quotes&quot;', esc_attr(attr)

    attr = "'single quotes'"
    assert_includes ['&#039;single quotes&#039;', '&#39;single quotes&#39;'], esc_attr(attr) # TODO Why isn't it &#039;?

    attr = "'mixed' " + '"quotes"'
    assert_includes ['&#039;mixed&#039; &quot;quotes&quot;', '&#39;mixed&#39; &quot;quotes&quot;'], esc_attr(attr)

    # # Handles double encoding?
    # attr = '"double quotes"'
    # assert_equal '&quot;double quotes&quot;', esc_attr(esc_attr(attr))
    #
    # attr = "'single quotes'"
    # assert_equal '&#039;single quotes&#039;', esc_attr(esc_attr(attr))
    #
    # attr = "'mixed' " + '"quotes"'
    # assert_equal '&#039;mixed&#039; &quot;quotes&quot;', esc_attr(esc_attr(attr))
  end

  # test "esc attr amp" do
  #   out = esc_attr 'foo & bar &baz; &nbsp;'
  #   assert_equal 'foo &amp; bar &amp;baz; &nbsp;', out
  # end

end