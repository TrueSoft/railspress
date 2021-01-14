require 'test_helper'

class Railspress::HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get railspress_home_index_url
    assert_response :success
  end

end
