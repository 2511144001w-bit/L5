class ProfilesController < ApplicationController
  before_action :require_login, except: :show
  before_action :set_user
  before_action :require_owner, except: :show
  before_action :set_profile, only: [:edit, :update, :destroy]

  def show
    @profile = @user.profile
  end

  def new
    if @user.profile
      redirect_to edit_user_profile_path(@user), notice: "プロフィールは登録済みです"
    else
      @profile = @user.build_profile
    end
  end

  def create
    if @user.profile
      redirect_to user_profile_path(@user), alert: "プロフィールは登録済みです", status: :see_other
      return
    end

    @profile = @user.build_profile(profile_params)

    if @profile.save
      redirect_to user_profile_path(@user), notice: "プロフィールを登録しました", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @profile.update(profile_params)
      redirect_to user_profile_path(@user), notice: "プロフィールを更新しました", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @profile.destroy!
    redirect_to user_profile_path(@user), notice: "プロフィールを削除しました", status: :see_other
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def require_owner
    unless @user == current_user
      redirect_to user_profile_path(@user), alert: "自分のプロフィールだけ変更できます", status: :see_other
    end
  end

  def set_profile
    @profile = @user.profile || raise(ActiveRecord::RecordNotFound)
  end

  def profile_params
    params.require(:profile).permit(:message)
  end
end
