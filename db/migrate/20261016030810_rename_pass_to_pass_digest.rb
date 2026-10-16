class RenamePassToPassDigest < ActiveRecord::Migration[8.1]
  def change
  rename_column :users, :pass, :pass_digest
  end
end
