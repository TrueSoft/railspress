require 'test_helper'

class Railspress::ArchiveControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get railspress_archive_index_url
    assert_response :success
  end

end
