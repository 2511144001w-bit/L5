require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  test "a profile belongs to one existing user and is reachable from that user" do
    profile = Profile.create!(user: users(:one), message: "Railsを学習しています。")

    assert_equal profile, users(:one).reload.profile
    assert_equal users(:one), profile.user
    assert_not Profile.new(message: "持ち主がいません").valid?
  end

  test "message is required and limited to 255 characters" do
    profile = Profile.new(user: users(:one), message: "あ" * 255)
    assert profile.valid?

    profile.message = "あ" * 256
    assert_not profile.valid?
    assert profile.errors.of_kind?(:message, :too_long)

    profile.message = "  "
    assert_not profile.valid?
    assert profile.errors[:message].any?
  end

  test "a user cannot have a second profile" do
    Profile.create!(user: users(:one), message: "最初のプロフィール")
    duplicate = Profile.new(user: users(:one), message: "二つ目のプロフィール")

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:user_id, :taken)
  end

  test "database unique index rejects a duplicate even without model validation" do
    Profile.create!(user: users(:one), message: "最初のプロフィール")

    assert_raises ActiveRecord::RecordNotUnique do
      Profile.transaction(requires_new: true) do
        Profile.insert_all!([{ user_id: users(:one).id, message: "重複" }])
      end
    end
  end

  test "deleting a user also deletes the profile" do
    user = User.create!(uid: "profile_owner", pass: "test-password")
    profile = user.create_profile!(message: "退会時に削除されます")

    assert_difference "Profile.count", -1 do
      user.destroy!
    end
    assert_not Profile.exists?(profile.id)
  end
end
