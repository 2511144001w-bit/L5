
class UsersController < ApplicationController
  before_action :require_login, only: :destroy

  # ユーザー一覧
  def index
    @users = User.order(:id)
  end

  # 新規登録画面
  def new
    @user = User.new
  end

  # ユーザー登録処理
  def create
    @user = User.new(user_params)

    if @user.save
      reset_session
      session[:login_uid] = @user.uid

      redirect_to root_path, notice: "登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # ユーザー削除処理
  def destroy
    user = User.find(params[:id])

    unless user == current_user
      redirect_to users_path,
                  alert: "自分のアカウントだけ削除できます"
      return
    end

    user.destroy!
    reset_session

    redirect_to root_path, notice: "削除しました"
  end

  private

  # 登録時に受け取るデータ
  def user_params
    params.require(:user).permit(
      :uid,
      :password,
      :password_confirmation,
      :age
    )
  end
end
