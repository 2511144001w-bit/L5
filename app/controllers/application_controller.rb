
class ApplicationController < ActionController::Base
  include CodespacesOriginProtection
  helper_method :current_user

  private

  def current_user
    return nil if session[:login_uid].blank?

    @current_user ||= User.find_by(uid: session[:login_uid])
  end

  def require_login
    unless current_user
      redirect_to login_path, alert: "ログインしてください"
    end
  end
end
