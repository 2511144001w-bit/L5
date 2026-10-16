require "test_helper"

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  setup do
    @previous_protection = ActionController::Base.allow_forgery_protection
    @previous_origin_check = ActionController::Base.forgery_protection_origin_check
    ActionController::Base.allow_forgery_protection = true
    ActionController::Base.forgery_protection_origin_check = true
  end

  teardown do
    ActionController::Base.allow_forgery_protection = @previous_protection
    ActionController::Base.forgery_protection_origin_check = @previous_origin_check
  end

  test "registration logs in and logout ends the session" do
    get new_user_path
    assert_difference "User.count", 1 do
      post users_path, params: registration_params.merge(authenticity_token: csrf_token),
        headers: { "HTTP_ORIGIN" => "http://www.example.com" }
    end
    assert_redirected_to root_path
    follow_redirect!
    assert_includes response.body, "ログイン中：auth_flow_user"
    assert User.find_by!(uid: "auth_flow_user").authenticate_pass("test-password")

    delete logout_path, params: { authenticity_token: csrf_token },
      headers: { "HTTP_ORIGIN" => "http://www.example.com" }
    assert_redirected_to root_path
    follow_redirect!
    assert_select "a[href=?]", login_path
    assert_not_includes response.body, "ログイン中："
  end

  test "existing user can log in" do
    get login_path
    post top_login_path, params: { uid: users(:one).uid, pass: "test-password", authenticity_token: csrf_token },
      headers: { "HTTP_ORIGIN" => "http://www.example.com" }
    assert_response :see_other
    assert_redirected_to root_path
    follow_redirect!
    assert_includes response.body, "ログイン中：#{users(:one).uid}"
  end

  test "wrong password shows a validation error" do
    get login_path
    post top_login_path, params: { uid: users(:one).uid, pass: "wrong-password", authenticity_token: csrf_token },
      headers: { "HTTP_ORIGIN" => "http://www.example.com" }
    assert_response :unprocessable_entity
    assert_includes response.body, "ユーザーIDまたはパスワードが違います"
  end

  test "registration rejects a duplicate uid and mismatched confirmation" do
    get new_user_path
    assert_no_difference "User.count" do
      post users_path, params: registration_params(uid: users(:one).uid).merge(authenticity_token: csrf_token),
        headers: { "HTTP_ORIGIN" => "http://www.example.com" }
    end
    assert_response :unprocessable_entity

    get new_user_path
    assert_no_difference "User.count" do
      post users_path, params: registration_params(pass_confirmation: "different-password").merge(authenticity_token: csrf_token),
        headers: { "HTTP_ORIGIN" => "http://www.example.com" }
    end
    assert_response :unprocessable_entity
  end

  test "Codespaces proxy supports registration logout and login with valid CSRF tokens" do
    with_codespaces do
      get new_user_path
      assert_difference "User.count", 1 do
        post users_path, params: registration_params.merge(authenticity_token: csrf_token), headers: proxy_headers
      end
      assert_redirected_to root_path
      follow_redirect!
      assert_includes response.body, "ログイン中：auth_flow_user"

      delete logout_path, params: { authenticity_token: csrf_token }, headers: proxy_headers
      assert_redirected_to root_path

      get login_path
      post top_login_path, params: { uid: "auth_flow_user", pass: "test-password", authenticity_token: csrf_token },
        headers: proxy_headers
      assert_response :see_other
      follow_redirect!
      assert_includes response.body, "ログイン中：auth_flow_user"
    end
  end

  test "Codespaces proxy still rejects missing or invalid CSRF tokens" do
    with_codespaces do
      get new_user_path
      assert_no_difference "User.count" do
        post users_path, params: registration_params, headers: proxy_headers
      end
      assert_response :unprocessable_entity

      get login_path
      post top_login_path, params: { uid: users(:one).uid, pass: "test-password", authenticity_token: "invalid" },
        headers: proxy_headers
      assert_response :unprocessable_entity
    end
  end

  test "Codespaces proxy rejects a cross site request even with a valid token" do
    with_codespaces do
      get new_user_path
      assert_no_difference "User.count" do
        post users_path, params: registration_params.merge(authenticity_token: csrf_token),
          headers: proxy_headers.merge("HTTP_SEC_FETCH_SITE" => "cross-site")
      end
      assert_response :unprocessable_entity
    end
  end

  private

  def csrf_token
    css_select('meta[name="csrf-token"]').first["content"]
  end

  def registration_params(**attributes)
    { user: { uid: "auth_flow_user", pass: "test-password", pass_confirmation: "test-password", age: 20 }.merge(attributes) }
  end

  def proxy_headers
    { "HTTP_ORIGIN" => "https://localhost:3000", "HTTP_SEC_FETCH_SITE" => "same-origin",
      "HTTP_REFERER" => "https://auth-test-3000.app.github.dev/login" }
  end

  def with_codespaces
    values = { "CODESPACES" => "true", "CODESPACE_NAME" => "auth-test", "GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN" => "app.github.dev" }
    previous = values.to_h { |key, _| [ key, ENV[key] ] }
    previous_rails_env = Rails.env
    values.each { |key, value| ENV[key] = value }
    host! "auth-test-3000.app.github.dev"
    https!
    Rails.env = "development"
    yield
  ensure
    Rails.env = previous_rails_env
    previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end
end
