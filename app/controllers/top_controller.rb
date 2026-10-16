
class TopController < ApplicationController
  def main
    @tweets = Tweet.includes(:user, :likes)
                   .order(created_at: :desc, id: :desc)
  end

  def login_form
  end

  def login
    uid = params[:uid].to_s.strip
    pass = params[:pass].to_s

    user = User.find_by(uid: uid)

    if user && user.authenticate_pass(pass)
      reset_session
      session[:login_uid] = user.uid

      redirect_to root_path,
                  notice: "ログインしました",
                  status: :see_other
    else
      flash.now[:alert] = "ユーザーIDまたはパスワードが違います"
      render :login_form, status: :unprocessable_entity
    end
  end

  def logout
    reset_session

    redirect_to root_path,
                notice: "ログアウトしました",
                status: :see_other
  end
end
