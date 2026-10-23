require "test_helper"

class TweetTest < ActiveSupport::TestCase
  test "like adds a user only once" do
    tweet = tweets(:one)
    user = users(:two)

    assert_not tweet.liked?(user)
    assert_difference "Like.count", 1 do
      tweet.like(user)
      tweet.like(user)
    end
    assert tweet.liked?(user)
  end

  test "unlike removes only the specified user's like and can be repeated" do
    tweet = tweets(:one)
    tweet.like(users(:two))

    assert_difference "Like.count", -1 do
      tweet.unlike(users(:one))
      tweet.unlike(users(:one))
    end

    assert_not tweet.liked?(users(:one))
    assert tweet.liked?(users(:two))
  end

  test "destroying a tweet also destroys its likes" do
    tweet = tweets(:one)
    tweet.like(users(:two))
    other_like = likes(:two)

    assert_difference "Like.count", -2 do
      tweet.destroy!
    end

    assert_not Like.exists?(tweet_id: tweet.id)
    assert Like.exists?(other_like.id)
  end
end
