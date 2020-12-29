require 'test_helper'

class ParseQueryTest < ActionView::TestCase

  # @ticket 29736
  test "parse query s array" do
    q = Railspress::WP_Query.new
    q.parse_query s: ['foo']
    assert_equal '', q.get('s')
  end

  test "parse query s string" do
    q = Railspress::WP_Query.new
    q.parse_query s: 'foo'
    assert_equal 'foo', q.get('s')
  end

  test "parse query s float" do
    q = Railspress::WP_Query.new
    q.parse_query s: 3.5
    assert_equal 3.5, q.get('s')
  end

  test "parse query s int" do
    q = Railspress::WP_Query.new
    q.parse_query s: 3
    assert_equal 3, q.get('s')
  end

  test "parse query s bool" do
    q = Railspress::WP_Query.new
    q.parse_query s: true
    assert_equal true, q.get('s')
  end

  # @ticket 33372
  test "parse query p negative int" do
    q = Railspress::WP_Query.new
    q.parse_query p: -3
    assert_equal '404', q.get('error')
  end

  # @ticket 33372
  test "parse query p array" do
    q = Railspress::WP_Query.new
    q.parse_query p: []
    assert_equal '404', q.get('error')
  end

  # @ticket 33372
  test "parse query p object" do
    q = Railspress::WP_Query.new
    q.parse_query p: Object.new
    assert_equal '404', q.get('error')
  end
end