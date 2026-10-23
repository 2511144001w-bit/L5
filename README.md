# L5

Rails 8.1 のつぶやきアプリです。ユーザー登録、ログイン、ログアウト、ツイート、いいね、プロフィール管理に対応しています。

## 第5回発展課題

User と Profile を `has_one` / `belongs_to` で1対1に関連付けています。
ログイン後の「自分のプロフィール」から自己紹介を登録・編集・削除できます。
自己紹介は必須で255文字以内です。ユーザー一覧やツイート投稿者名からプロフィールを閲覧できます。
編集操作は本人だけに許可し、`user_id` の一意インデックスで二重登録を防ぎます。

## 第6回基礎課題

第5回のアプリを使い、演習1の機能に対応しています。

- `current_user` をコントローラーとビューから使い、ログイン中のユーザーを取得します。
- `User` の `like(tweet)`・`unlike(tweet)`・`liked?(tweet)` で、いいねの追加・解除・判定を行います。処理は講義例に合わせた `Tweet` の各メソッドを呼び出し、同じ操作を繰り返しても重複やエラーが生じないようにしています。
- `dependent: :destroy` により、ユーザー削除時にそのユーザーのツイート・いいね・プロフィールを削除し、ツイート削除時にはそのツイートへのいいねを削除します。
- 登録フォームの `password` と `password_confirmation` が一致し、確認欄が入力されていることを検証します。`has_secure_password` で保存・認証し、既存の `pass_digest` 列を `password_digest` 列へ変更して登録済みのパスワード情報を引き継ぎます。

既存の環境で今回の変更を取り込んだ後は、次を実行してデータベースを更新し、起動中のサーバーを再起動してください。

~~~sh
bin/rails db:migrate
~~~

## 開発環境で起動

Ruby は .ruby-version に合わせてください。

~~~sh
bundle install
bin/rails db:prepare
bin/rails server -b 0.0.0.0
~~~

Codespaces ではポート 3000 の転送先をブラウザーで開きます。
新規登録は /users/new、ログインは /login です。登録後は自動でログインします。

## Codespaces でログイン・登録が 422 になる場合

Codespaces の転送により Origin が localhost:3000 に変わり、Rails の送信元チェックと一致しないことがあります。
CodespacesOriginProtection は開発環境の現在の Codespace・ポート 3000 に限り、ブラウザーの Sec-Fetch-Site と Referer が同じ送信元を示す場合に対応します。
CSRFトークンの検証は有効なままで、本番環境では通常の Rails の送信元チェックが使われます。

## テスト

~~~sh
bin/rails db:test:prepare
bin/rails test
~~~

登録、ログアウト、再ログイン、入力エラー、Codespaces の送信元処理、および不正な CSRFトークン・外部サイトからの送信拒否を検証します。
プロフィールのCRUD、公開閲覧、未ログイン・他人による変更の拒否、所有者IDの偽装、文字数境界、重複、HTMLエスケープ、連動削除も検証します。
第6回のテストでは、いいねの追加・解除・判定、操作の繰り返し、他人のいいねの保護、ユーザー・ツイート削除の伝搬、パスワード確認の一致・不一致・未入力を検証します。

## Renderへの配置

Ruby 3.4.9、Build Command `bash bin/render-build.sh`、Start Command `bundle exec puma -C config/puma.rb` を使用します。
環境変数 `RAILS_ENV=production`、`SECRET_KEY_BASE`、既存PostgreSQLの `DATABASE_URL` を設定します。
接続情報や秘密鍵はリポジトリへ保存しません。

本番DB内の `swexe_l5` スキーマへ第5回用のテーブルを作成します。
ビルド時に接続先スキーマを確認し、既存の `public` スキーマのテーブルは変更しません。
キャッシュ・ジョブ・WebSocketは今回使用しないため、専用DBが不要なmemory/async構成です。
