require "test_helper"
require "rack/mock"
require "action_controller/metal/request_forgery_protection"

class CodespacesOriginProtectionTest < Minitest::Test
  FORWARDED_ORIGIN = "https://test-codespace-3000.app.github.dev"
  CODESPACES_ENV = {
    "CODESPACES" => "true",
    "CODESPACE_NAME" => "test-codespace",
    "GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN" => "app.github.dev"
  }.freeze

  class OriginCheck
    attr_reader :request

    def initialize(request)
      @request = request
    end

    def allowed?
      valid_request_origin?
    end

    private

    def valid_request_origin?
      raise ActionController::InvalidAuthenticityToken if request.origin == "null"

      request.origin.nil? || request.origin == request.base_url
    end
  end

  class ProtectedOriginCheck < OriginCheck
    include CodespacesOriginProtection
  end

  def setup
    @original_env = ENV.to_h.slice(*CODESPACES_ENV.keys)
    ENV.update(CODESPACES_ENV)
  end

  def teardown
    CODESPACES_ENV.each_key do |key|
      @original_env.key?(key) ? ENV[key] = @original_env.fetch(key) : ENV.delete(key)
    end
  end

  def test_accepts_same_origin_codespaces_proxy_requests
    %w[http://localhost:3000 https://localhost:3000].each do |origin|
      assert origin_allowed?(origin: origin), origin
    end
  end

  def test_requires_same_origin_fetch_metadata
    [ nil, "cross-site", "same-site", "none" ].each do |fetch_site|
      refute origin_allowed?(fetch_site: fetch_site), fetch_site.inspect
    end
  end

  def test_requires_valid_https_referer_from_exact_forwarded_origin
    [ nil, "https://%", "https://other-3000.app.github.dev/login",
      "http://test-codespace-3000.app.github.dev/login",
      "https://test-codespace-3000.app.github.dev:444/login" ].each do |referer|
      refute origin_allowed?(referer: referer), referer.inspect
    end
  end

  def test_rejects_other_codespaces_and_ports
    [ "https://other-3000.app.github.dev", "https://test-codespace-4000.app.github.dev",
      "https://test-codespace-3000.app.github.dev:444" ].each do |origin|
      refute origin_allowed?(url: "#{origin}/users", referer: "#{origin}/signup"), origin
    end
  end

  def test_rejects_other_origin_values
    [ "https://attacker.example", "https://localhost:4000", "http://127.0.0.1:3000" ].each do |origin|
      refute origin_allowed?(origin: origin), origin
    end
  end

  def test_requires_all_codespaces_environment_values
    CODESPACES_ENV.each_key do |key|
      original = ENV.delete(key)
      refute origin_allowed?, key
      ENV[key] = original
    end

    ENV["CODESPACES"] = "false"
    refute origin_allowed?
  end

  def test_rejects_proxy_origin_in_production
    refute origin_allowed?(environment: "production")
  end

  def test_preserves_default_origin_validation
    assert origin_allowed?(origin: FORWARDED_ORIGIN, fetch_site: nil, referer: nil)
    assert origin_allowed?(origin: nil, fetch_site: nil, referer: nil)
    assert_raises(ActionController::InvalidAuthenticityToken) { origin_allowed?(origin: "null") }
  end

  private

  def origin_allowed?(origin: "https://localhost:3000", url: "#{FORWARDED_ORIGIN}/users",
    fetch_site: "same-origin", referer: "#{FORWARDED_ORIGIN}/signup", environment: "development")
    env = Rack::MockRequest.env_for(url, method: "POST")
    env["HTTP_ORIGIN"] = origin unless origin.nil?
    env["HTTP_SEC_FETCH_SITE"] = fetch_site unless fetch_site.nil?
    env["HTTP_REFERER"] = referer unless referer.nil?

    previous_rails_env = Rails.env
    Rails.env = environment
    ProtectedOriginCheck.new(ActionDispatch::Request.new(env)).allowed?
  ensure
    Rails.env = previous_rails_env if previous_rails_env
  end
end
