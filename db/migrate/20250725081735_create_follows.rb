class CreateFollows < ActiveRecord::Migration[7.1]
  def change
    create_table :follows do |t|
      t.bigint :follower_id
      t.bigint :followed_id

      t.timestamps
    end

    add_index :follows, :follower_id, name: 'index_follows_on_follower_id'
    add_index :follows, :followed_id, name: 'index_follows_on_followed_id'
    add_index :follows, [:follower_id, :followed_id], unique: true, name: 'index_follows_on_follower_id_and_followed_id'
  end
end
