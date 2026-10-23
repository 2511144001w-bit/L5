class RenamePassDigestToPasswordDigest < ActiveRecord::Migration[8.1]
  # 追加
  def change
    rename_column :users, :pass_digest, :password_digest
  end
end
