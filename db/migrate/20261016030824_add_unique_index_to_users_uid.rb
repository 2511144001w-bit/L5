class AddUniqueIndexToUsersUid < ActiveRecord::Migration[8.1]
  def change
  add_index :users, :uid, unique: true
  end
end
