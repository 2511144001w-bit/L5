class Profile < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :message, presence: { message: "を入力してください" },
    length: { maximum: 255, message: "は255文字以内で入力してください" }
end
