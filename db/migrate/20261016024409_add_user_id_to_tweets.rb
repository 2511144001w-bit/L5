class AddUserIdToTweets < ActiveRecord::Migration[8.1]
  def change
    add_column :tweets, :user_id, :integer
  end
end
