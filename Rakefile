require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "salesforce-sync"
  gem.homepage = "http://github.com/DerGuteMoritz/salesforce-sync"
  gem.license = "MIT"
  gem.summary = %Q{Synchronize Salesforce objects into a local database}
  gem.description = %Q{This gem provides a program named salesforce-sync which allows you to synchronize Salesforce objects into a local database. Currently only unidirectional synchronization from Salesforce into a local database is implemented.}
  gem.email = "moritz@twoticketsplease.de"
  gem.authors = ["Moritz Heidkamp", "Christof Spies"]
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  #  gem.add_runtime_dependency 'jabber4r', '> 0.1'
  #  gem.add_development_dependency 'rspec', '> 1.2.3'

  gem.add_runtime_dependency 'activesupport', '= 3.0.3'
  gem.add_runtime_dependency 'activerecord', '= 3.0.3'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "salesforce-sync #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :default => :build
