
class TweetsController < ApplicationController
  before_action :require_login

  def create
    tweet = current_user.tweets.build(tweet_params)

    if tweet.save
      redirect_to root_path,
                  notice: "ツイートを投稿しました",
                  status: :see_other
    else
      redirect_to root_path,
                  alert: tweet.errors.full_messages.join("、"),
                  status: :see_other
    end
  end

  def destroy
    tweet = current_user.tweets.find(params[:id])
    tweet.destroy!

    redirect_to root_path,
                notice: "ツイートを削除しました",
                status: :see_other
  end

  private

  def tweet_params
    params.require(:tweet).permit(:message)
  end
end
