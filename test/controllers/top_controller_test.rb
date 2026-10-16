require "test_helper"

class TopControllerTest < ActionDispatch::IntegrationTest
  test "should get main" do
    get root_url
    assert_response :success
  end

  test "should get login form" do
    get login_url
    assert_response :success
  end
end
