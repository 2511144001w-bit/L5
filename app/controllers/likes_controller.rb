class LikesController < ApplicationController
  before_action :require_login

  def create
    tweet = Tweet.find(params[:tweet_id])

    current_user.likes.find_or_create_by!(tweet: tweet)

    redirect_to root_path, notice: "いいねしました"
  end

  def destroy
    like = current_user.likes.find(params[:id])
    like.destroy!

    redirect_to root_path, notice: "いいねを取り消しました"
  end
end