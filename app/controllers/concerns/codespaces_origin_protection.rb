require "uri"

module CodespacesOriginProtection
  extend ActiveSupport::Concern

  private

  def valid_request_origin?
    super || codespaces_same_origin_request?
  end

  def codespaces_same_origin_request?
    return false unless Rails.env.development? && ENV["CODESPACES"] == "true"

    name = ENV["CODESPACE_NAME"]
    domain = ENV["GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN"]
    return false if name.blank? || domain.blank?
    return false unless request.base_url == "https://#{name}-3000.#{domain}"
    return false unless %w[http://localhost:3000 https://localhost:3000].include?(request.origin)
    return false unless request.headers["Sec-Fetch-Site"] == "same-origin"

    # Codespaces rewrites Origin; retain independent browser same-origin checks.
    referer = URI.parse(request.referer.to_s)
    referer.scheme == "https" && referer.host == request.host && referer.port == request.port
  rescue URI::InvalidURIError
    false
  end
end
