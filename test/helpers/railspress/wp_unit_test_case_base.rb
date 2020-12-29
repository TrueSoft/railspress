class WP_UnitTestCase_Base < ActionDispatch::IntegrationTest

  def assert_query_true(*args)
    all = [
      # 'is_404',
      # 'is_admin',
      'is_archive',
      'is_attachment',
      'is_author',
      'is_category',
      # 'is_comment_feed',
      'is_date',
      'is_day',
      # 'is_embed',
      # 'is_feed',
      'is_front_page',
      'is_home',
      'is_privacy_policy',
      # 'is_month',
      'is_page',
      # 'is_paged',
      'is_post_type_archive',
      # 'is_posts_page',
      # 'is_preview',
      # 'is_robots',
      # 'is_search',
      'is_single',
      'is_singular',
      'is_tag',
      'is_tax',
      # 'is_time',
      # 'is_trackback',
      # 'is_year',
    ]
    args.each do |true_thing|
      assert all.include?(true_thing), "Unknown conditional: #{true_thing}."
    end
    passed = true
    message = ''
    wp_query = @controller.instance_variable_get(:@wp_query)
    all.each do |query_thing|
      if wp_query.respond_to?((query_thing +'?').to_sym)
        result = wp_query.send((query_thing + '?').to_sym)
      else
        result = wp_query.send(query_thing.to_sym) # $result = is_callable( $query_thing ) ? call_user_func( $query_thing ) : $wp_query->$query_thing;
      end
      if args.include? query_thing
        unless result
          message += "#{query_thing} is false but is expected to be true. \n"
          passed = false
        end
      elsif result
        message += "#{query_thing} is true but is expected to be false. \n"
        passed = false
      end
    end
    raise Minitest::Assertion, message unless passed
  end
end