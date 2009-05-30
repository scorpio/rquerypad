require File.dirname(__FILE__) + '/test_helper'


require 'rquerypad'
require 'test/model'
class RquerypadTest < THE_TEST_CLASS
  # Replace this with your real tests.
  include Model
  def test_this_plugin
    @fixture_path = 'vendor/plugins/rquerypad/test/fixtures'
    
    @users = User.find(:all, :group => ["threads.created_at", "name"])
    p @users
    assert_equal  @users.size, 2

    c = User.count(:conditions => ["threads_.replies.title = ?", "rquerypad"])
    assert_equal  c, 1

    @users = User.find(:all, :conditions => ["threads.replies.title = ? and threads.id = ?", "rquerypad", 1])
    assert_equal  @users.size, 1

    @users = User.find(:all, :conditions => ["threads.replies.title = :title and threads.id = :id", {:title => "rquerypad", :id => 1}])
   assert_equal  @users.size, 1

    @replies = ForumReply.find(:all, :conditions => ["thread.id = ?", 2])
   assert_equal  @replies.size, 3

    @replies = ForumReply.find(:all, :conditions => ["id = ?", 2])
    assert_equal  @replies.size, 1

    @replies = User.find(:all, :conditions => ["id = ?", 2])
   assert_equal  @replies.size, 1

  end
end
