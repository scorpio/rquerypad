ENV["RAILS_ENV"] = "rquerypad"
require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")
require 'test_help'
THE_TEST_CLASS = eval(RAILS_GEM_VERSION >= "2.3" ? "ActiveSupport::TestCase" : "Test::Unit::TestCase")
THE_TEST_CLASS.fixture_path = File.expand_path(File.dirname(__FILE__) + "/fixtures/")
class THE_TEST_CLASS
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  fixtures :all
end
