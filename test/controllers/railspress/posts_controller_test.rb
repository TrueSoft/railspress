require 'test_helper'

module Railspress
  class PostsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test "should get index" do
      get posts_url
      assert_response :success
    end

    test "should get show" do
      get posts_show_url
      assert_response :success
    end

  end
end
