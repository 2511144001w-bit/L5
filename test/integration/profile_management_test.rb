require "test_helper"

class ProfileManagementTest < ActionDispatch::IntegrationTest
  test "anyone can view a profile or an unregistered profile" do
    get user_profile_path(users(:one))
    assert_response :success
    assert_includes response.body, "プロフィールは未登録です。"
    assert_select "a[href=?]", new_user_profile_path(users(:one)), count: 0

    users(:one).create_profile!(message: "趣味はプログラミングです。")
    get user_profile_path(users(:one))
    assert_response :success
    assert_includes response.body, "趣味はプログラミングです。"
    assert_select "a[href=?]", edit_user_profile_path(users(:one)), count: 0
    assert_select "form[action=?]", user_profile_path(users(:one)), count: 0
  end

  test "owner can create update and delete a profile without deleting the account" do
    user = users(:one)
    sign_in(user)

    get new_user_profile_path(user)
    assert_response :success
    assert_select "textarea[name=?][maxlength=?]", "profile[message]", "255"

    assert_difference "Profile.count", 1 do
      post user_profile_path(user), params: { profile: { message: "福岡県でRailsを学んでいます。" } }
    end
    assert_redirected_to user_profile_path(user)
    follow_redirect!
    assert_includes response.body, "プロフィールを登録しました"
    assert_includes response.body, "福岡県でRailsを学んでいます。"
    assert_select "a[href=?]", edit_user_profile_path(user)

    get edit_user_profile_path(user)
    assert_response :success
    assert_select "input[name=?][value=?]", "_method", "patch"

    assert_no_difference "Profile.count" do
      patch user_profile_path(user), params: { profile: { message: "モデル間の関連付けを学びました。" } }
    end
    assert_redirected_to user_profile_path(user)
    assert_equal "モデル間の関連付けを学びました。", user.reload.profile.message

    assert_no_difference ["User.count", "Tweet.count", "Like.count"] do
      assert_difference "Profile.count", -1 do
        delete user_profile_path(user)
      end
    end
    assert_redirected_to user_profile_path(user)
    follow_redirect!
    assert_includes response.body, "プロフィールは未登録です。"
    assert_select "a[href=?]", new_user_profile_path(user)

    get root_path
    assert_includes response.body, "ログイン中：#{user.uid}"
  end

  test "blank and oversized messages are rejected without changing saved data" do
    user = users(:one)
    sign_in(user)

    assert_no_difference "Profile.count" do
      post user_profile_path(user), params: { profile: { message: "  " } }
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "を入力してください"

    user.create_profile!(message: "元の自己紹介")
    patch user_profile_path(user), params: { profile: { message: "あ" * 256 } }
    assert_response :unprocessable_entity
    assert_includes response.body, "255文字以内"
    assert_equal "元の自己紹介", user.reload.profile.message
  end

  test "a second create request does not replace or duplicate the profile" do
    user = users(:one)
    profile = user.create_profile!(message: "元の自己紹介")
    sign_in(user)

    get new_user_profile_path(user)
    assert_redirected_to edit_user_profile_path(user)

    assert_no_difference "Profile.count" do
      post user_profile_path(user), params: { profile: { message: "二つ目の自己紹介" } }
    end
    assert_redirected_to user_profile_path(user)
    assert_equal "元の自己紹介", profile.reload.message
  end

  test "anonymous visitors cannot open forms or change a profile" do
    user = users(:one)
    profile = user.create_profile!(message: "保護する自己紹介")

    get new_user_profile_path(user)
    assert_redirected_to login_path
    get edit_user_profile_path(user)
    assert_redirected_to login_path

    assert_no_difference "Profile.count" do
      post user_profile_path(user), params: { profile: { message: "不正な登録" } }
      assert_redirected_to login_path
      patch user_profile_path(user), params: { profile: { message: "不正な更新" } }
      assert_redirected_to login_path
      delete user_profile_path(user)
      assert_redirected_to login_path
    end
    assert_equal "保護する自己紹介", profile.reload.message
  end

  test "another logged in user cannot create edit update or delete the owner's profile" do
    owner = users(:one)
    sign_in(users(:two))

    assert_no_difference "Profile.count" do
      post user_profile_path(owner), params: { profile: { message: "なりすまし" } }
      assert_redirected_to user_profile_path(owner)
    end

    profile = owner.create_profile!(message: "本人の自己紹介")
    get new_user_profile_path(owner)
    assert_redirected_to user_profile_path(owner)
    get edit_user_profile_path(owner)
    assert_redirected_to user_profile_path(owner)

    assert_no_difference "Profile.count" do
      patch user_profile_path(owner), params: { profile: { message: "なりすまし更新" } }
      assert_redirected_to user_profile_path(owner)
      delete user_profile_path(owner)
      assert_redirected_to user_profile_path(owner)
    end
    assert_equal "本人の自己紹介", profile.reload.message
  end

  test "submitted user id cannot transfer profile ownership" do
    user = users(:one)
    sign_in(user)

    post user_profile_path(user), params: { profile: { message: "自分の自己紹介", user_id: users(:two).id } }
    assert_redirected_to user_profile_path(user)
    assert_equal user.id, user.reload.profile.user_id
    assert_nil users(:two).reload.profile

    patch user_profile_path(user), params: { profile: { message: "更新後", user_id: users(:two).id } }
    assert_equal user.id, user.reload.profile.user_id
    assert_nil users(:two).reload.profile
  end

  test "profile text is escaped and links are available from users and tweets" do
    user = users(:one)
    user.create_profile!(message: '<script>alert("test")</script>')

    get user_profile_path(user)
    assert_response :success
    assert_includes response.body, "&lt;script&gt;"
    assert_select "script", text: 'alert("test")', count: 0

    get users_path
    assert_select "a[href=?]", user_profile_path(user), text: user.uid
    get root_path
    assert_select "a[href=?]", user_profile_path(user), text: user.uid
  end

  private

  def sign_in(user)
    post top_login_path, params: { uid: user.uid, pass: "test-password" }
    assert_redirected_to root_path
  end
end
