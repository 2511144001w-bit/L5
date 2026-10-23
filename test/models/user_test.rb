require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "matching password confirmation stores a digest and authenticates" do
    user = User.create!(uid: "lesson6", password: "test-password", password_confirmation: "test-password")
    assert_not_equal "test-password", user.password_digest
    assert user.authenticate("test-password")
    assert_not user.authenticate("wrong-password")
  end

  test "missing or mismatched confirmation cannot create an account" do
    [ nil, "", "different-password" ].each do |confirmation|
      user = User.new(uid: "lesson6", password: "test-password", password_confirmation: confirmation)
      assert_not user.valid?
      assert user.errors[:password_confirmation].any?
    end
  end

  test "user like methods operate only on that users likes" do
    user = users(:one)
    tweet = tweets(:two)
    assert_not user.liked?(tweet)
    assert_difference "Like.count", 1 do
      user.like(tweet)
      user.like(tweet)
    end
    assert user.liked?(tweet)
    user.unlike(tweet)
    assert_not user.liked?(tweet)
    assert users(:two).liked?(tweet)
  end

  test "destroying a user removes tweets and related likes but keeps other users data" do
    owner = users(:one)
    other = users(:two)
    own_tweet = tweets(:one)
    other_tweet = tweets(:two)
    owner.like(other_tweet)
    other.like(own_tweet)
    owner.create_profile!(message: "削除確認")

    assert_difference({ "User.count" => -1, "Tweet.count" => -1, "Like.count" => -3, "Profile.count" => -1 }) do
      owner.destroy!
    end
    assert_not Tweet.exists?(own_tweet.id)
    assert_not Like.exists?(user_id: owner.id)
    assert_not Like.exists?(tweet_id: own_tweet.id)
    assert User.exists?(other.id)
    assert Tweet.exists?(other_tweet.id)
    assert Like.exists?(user: other, tweet: other_tweet)
  end
end
