class Tweet < ApplicationRecord
  belongs_to :user

  has_many :likes, dependent: :destroy
  has_many :like_users, through: :likes, source: :user

  validates :message, presence: true, length: { maximum: 255 }

  def like(user)
    likes.find_or_create_by!(user: user)
  end

  def unlike(user)
    likes.where(user: user).destroy_all
  end

  def liked?(user)
    likes.exists?(user: user)
  end
end
