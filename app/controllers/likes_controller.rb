class LikesController < ApplicationController
  before_action :require_login

  def create
    tweet = Tweet.find(params[:tweet_id])

    current_user.like(tweet)

    redirect_to root_path, notice: "いいねしました"
  end

  def destroy
    tweet = Tweet.find(params[:id])
    current_user.unlike(tweet)

    redirect_to root_path, notice: "いいねを取り消しました"
  end
end
