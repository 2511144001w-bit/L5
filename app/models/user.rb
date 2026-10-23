class User < ApplicationRecord
  has_secure_password

  validates :uid, presence: true, uniqueness: true
  validates :password_confirmation, presence: true, on: :create

  has_one :profile, dependent: :destroy
  has_many :tweets, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :like_tweets, through: :likes, source: :tweet

  # 追加
  def like(tweet)
    tweet.like(self)
  end

  def unlike(tweet)
    tweet.unlike(self)
  end

  def liked?(tweet)
    tweet.liked?(self)
  end
end
