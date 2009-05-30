class CreateReplies < ActiveRecord::Migration
  def self.up
    create_table :forum_replies do |t|
      t.string  "title"
      t.string  "content"
      t.integer "user_id"
      t.integer "forum_thread_id"
      t.integer "parent_id"
      t.datetime  "created_at"
      t.datetime  "updated_at"
    end
  end

  def self.down
    drop_table :forum_replies
  end
end
