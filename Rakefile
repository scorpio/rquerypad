require 'rake'
require 'rubygems'
require 'rake/gempackagetask'
require 'rake/testtask'
require 'rake/rdoctask'

PKG_NAME = "rquerypad"
PKG_VERSION = "0.1.23"
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"
PKG_FILES = FileList[
  '[A-Z]*',
  'lib/**/*',
  'tasks/**/*',
  'test/**/*'
]
spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = "Simplify query with OO way and improve inner join for ActiveRecord"
  s.name = PKG_NAME
  s.version = PKG_VERSION
  s.require_path = 'lib'
  s.homepage = %q{http://rquerypad.rubyforge.org/}
  s.rubyforge_project = 'Rquerypad'
  s.has_rdoc = false
  s.authors = ["Leon Li"]
  s.email = "scorpio_leon@hotmail.com"
  s.files = PKG_FILES
  s.description = <<-EOF
    Simplify query options with association automation and improve inner join for ActiveRecord of rails by providing a compact and OO query language instead of writing some explicit join
  EOF
end
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the rquerypad plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the rquerypad plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Rquerypad'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Create the database defined in config/database.yml for the current RAILS_ENV'
require 'activerecord'
task :migrate  do
  config = {'adapter' => "sqlite3", 'database' => "test/db.rquerypad", 'timeout' => 5000}
  begin
    FileUtils.rm_f(File.dirname(__FILE__) + "/" + config['database'])
  rescue
  end
  begin
    ActiveRecord::Base.establish_connection(config)
    ActiveRecord::Base.connection
  rescue
    `sqlite3 "#{config['database']}"`
  end
  ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/migrate.log")
  ActiveRecord::Migrator.migrate("test/migrate/")
end



