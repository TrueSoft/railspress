require 'test_helper'

require 'helpers/railspress/wp_unit_test_case_base'

class QueryConditionalsTest < WP_UnitTestCase_Base
  include Railspress::OptionsHelper
  include Railspress::Plugin
  include Railspress::TaxonomyLib
  include Railspress::LinkTemplateHelper
  include Railspress::PostsHelper
  include Railspress::FormattingHelper
  include Railspress::CategoryTemplateHelper

  fixtures 'railspress/posts'.to_sym
  fixtures 'railspress/pages'.to_sym
  fixtures 'railspress/categories'.to_sym
  fixtures 'railspress/post_tags'.to_sym
  fixtures 'railspress/users'.to_sym

  setup do
    # TODO set_current_screen( 'front' )

    update_option 'comments_per_page', 5
    update_option 'posts_per_page', 5

    # TODO set_permalink_structure( '/%year%/%monthnum%/%day%/%postname%/' )

    create_initial_taxonomies
  end

  test "home" do
    get "/"
    assert_query_true 'is_home', 'is_front_page'
  end

  test "page on front" do
    page_on_front = railspress_pages(:page_on_front)
    page_for_posts = Railspress::WpPost.new post_type: 'page'

    update_option('show_on_front', 'page')
    update_option('page_on_front', page_on_front.id)
    update_option('page_for_posts', page_for_posts.id)
    get "/"
    assert_query_true 'is_front_page', 'is_page', 'is_singular'

    # get get_permalink(page_for_posts)
    # assert_query_true 'is_home', 'is_posts_page'

    update_option('show_on_front', 'posts')
    delete_option('page_on_front')
    delete_option('page_for_posts')
  end

  test "404" do
    assert_raises(ActionController::RoutingError) { get "/notapage" }
    # assert_query_true 'is_404' - not using is_404
  end

  test "permalink" do
    # hello_world created in fixtures
    post_id = railspress_posts(:hello_world)
    get get_permalink(post_id)
    assert_query_true 'is_single', 'is_singular'
  end

  # test_post_comments_feed test_post_comments_feed_with_no_comments test_attachment_comments_feed

  test "page" do
    # about created in fixtures
    page_id = railspress_pages(:about)
    get get_permalink(page_id)
    assert_query_true 'is_page', 'is_singular'
  end

  test "parent page" do
    page_id = railspress_pages(:parent_page)
    get get_permalink(page_id)
    assert_query_true 'is_page', 'is_singular'
  end

  test "child page 1" do
    page_id = railspress_pages(:child_page_1)
    get get_permalink(page_id)
    assert_query_true 'is_page', 'is_singular'
  end

  test "child page 2" do
    page_id = railspress_pages(:child_page_2)
    get get_permalink(page_id)
    assert_query_true 'is_page', 'is_singular'
  end

  test "category" do
    cat_a = railspress_categories(:cat_a)
    assert_equal 'category', cat_a.taxonomy
    assert_equal 'cat-a', cat_a.term.slug
    get "/category/cat-a/"
    assert_query_true 'is_archive', 'is_category'
  end

  test "tag" do
    term_id = railspress_post_tags(:tag_a)
    get "/tag/tag-a/"
    assert_query_true 'is_archive', 'is_tag'
    tag = get_term(term_id, 'post_tag')

    # assert is_tag()
  end

  test "author" do
    user_id = railspress_users(:user_a)
    get '/author/user-a/'
    assert_query_true 'is_archive', 'is_author'
  end

  test "is privacy policy" do
    page_id = railspress_pages(:privacy_policy)

    update_option 'wp_page_for_privacy_policy', page_id.id

    get get_permalink(page_id)
    wp_query = @controller.instance_variable_get(:@wp_query)
    assert_query_true 'is_page', 'is_singular', 'is_privacy_policy'
  end
end