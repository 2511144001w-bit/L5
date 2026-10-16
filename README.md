# L5

Rails 8.1 のつぶやきアプリです。ユーザー登録、ログイン、ログアウト、ツイート、いいねに対応しています。

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
bin/rails test
~~~

登録、ログアウト、再ログイン、入力エラー、Codespaces の送信元処理、および不正な CSRFトークン・外部サイトからの送信拒否を検証します。
