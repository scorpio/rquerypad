module Model
  class User < ActiveRecord::Base
    has_many :threads, :class_name => "Model::ForumThread"
    has_many :repliess, :class_name => "Model::ForumReply"
  end
  class ForumThread < ActiveRecord::Base
    has_many :replies, :class_name => "Model::ForumReply"
    belongs_to :user
  end
  class ForumReply < ActiveRecord::Base
    belongs_to :thread, :class_name => "Model::ForumThread"
    has_many :replies, :class_name => "Model::ForumReply"
    belongs_to :reply, :foreign_key => "parent_id", :class_name => "Model::ForumReply"
    belongs_to :user
    acts_as_tree
  end
end