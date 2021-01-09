require 'test_helper'

class QueryTest < ActionView::TestCase
  include Railspress::TaxonomyLib

  # @ticket 35619
  test "query vars should match first of multiple terms" do
    register_taxonomy 'tax1', 'post'
    register_taxonomy 'tax2', 'post'

    # TODO continue

    # term1 = Railspress::Term.new(taxonomy: 'tax1', name: 'term1')
    # term2 = Railspress::Term.new(taxonomy: 'tax2', name: 'term2')
    #
    # post_id = Railspress::Post.new
    # $post_id = $this->factory->post->create();
    # wp_set_object_terms( $post_id, 'term1', 'tax1' );
    # wp_set_object_terms( $post_id, 'term2', 'tax2' );
    #
    # $this->go_to( home_url( '?tax1=term1&tax2=term2' ) );
    # $queried_object = get_queried_object();
    #
    # $this->assertSame( 'tax1', get_query_var( 'taxonomy' ) );
    # $this->assertSame( 'term1', get_query_var( 'term' ) );
  end

end