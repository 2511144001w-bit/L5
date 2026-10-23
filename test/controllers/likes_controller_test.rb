require "test_helper"

class LikesControllerTest < ActionDispatch::IntegrationTest
  test "login is required to like or unlike" do
    assert_no_difference "Like.count" do
      post likes_url, params: { tweet_id: tweets(:two).id }
      assert_redirected_to login_url

      delete like_url(tweets(:one))
      assert_redirected_to login_url
    end
  end

  test "liking repeatedly creates only one like for the signed in user" do
    log_in
    tweet = tweets(:two)

    assert_difference "Like.count", 1 do
      2.times do
        post likes_url, params: { tweet_id: tweet.id }
        assert_redirected_to root_url
      end
    end

    assert tweet.liked?(users(:one))
    assert tweet.liked?(users(:two))
  end

  test "unlike uses the tweet id and preserves another user's like" do
    log_in
    tweet = tweets(:two)
    own_like = tweet.like(users(:one))
    assert_not_equal tweet.id, own_like.id

    assert_difference "Like.count", -1 do
      2.times do
        delete like_url(tweet)
        assert_redirected_to root_url
      end
    end

    assert_not tweet.liked?(users(:one))
    assert tweet.liked?(users(:two))
  end

  test "unliking a tweet liked only by someone else changes nothing" do
    log_in
    tweet = tweets(:two)

    assert_no_difference "Like.count" do
      delete like_url(tweet)
    end

    assert_redirected_to root_url
    assert tweet.liked?(users(:two))
  end

  test "the timeline uses the tweet id in its unlike button" do
    log_in
    tweet = tweets(:two)
    own_like = tweet.like(users(:one))
    assert_not_equal tweet.id, own_like.id

    get root_url

    assert_response :success
    assert_select "form[action=?]", like_path(tweet) do
      assert_select "input[name='_method'][value='delete']"
      assert_select "button", text: "いいね削除"
    end
    assert_select "form[action=?]", like_path(own_like), count: 0
  end

  private

  def log_in
    post top_login_url, params: { uid: users(:one).uid, pass: "test-password" }
    assert_redirected_to root_url
  end
end
