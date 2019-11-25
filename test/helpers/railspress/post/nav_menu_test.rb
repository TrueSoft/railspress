require 'test_helper'

class NavMenuTest < ActionView::TestCase

  include Railspress::NavMenuHelper
  include Railspress::Plugin
  include Railspress::TaxonomyLib

  attr_accessor :menu_id

  setup do
    @menu_id = wp_create_nav_menu(rand_str)
  end

  def rand_str
    (0...8).map { (65 + rand(26)).chr }.join
  end

  test "one" do
    assert_equal '1', 1.to_s
  end

end