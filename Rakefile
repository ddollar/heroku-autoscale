require "rake"
require "rspec"
require "rspec/core/rake_task"

$:.unshift File.expand_path("../lib", __FILE__)
require "heroku/autoscale"

task :default => :spec
task :release => :man

desc "Run all specs"
Rspec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

desc "Generate RCov code coverage report"
task :rcov => "rcov:build" do
  %x{ open coverage/index.html }
end

Rspec::Core::RakeTask.new("rcov:build") do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rcov = true
  t.rcov_opts = [ "--exclude", Gem.default_dir , "--exclude", "spec" ]
end

######################################################

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name    = "heroku-autoscale"
    s.version = Heroku::Autoscale::VERSION

    s.summary     = "Autoscale your Heroku dynos"
    s.description = s.summary
    s.author      = "David Dollar"
    s.email       = "ddollar@gmail.com"
    s.homepage    = "http://github.com/ddollar/heroku-autoscale"

    s.platform = Gem::Platform::RUBY
    s.has_rdoc = false

    s.files = %w(Rakefile README.md) + Dir["{bin,export,lib,spec}/**/*"]
    s.require_path = "lib"

    s.add_development_dependency 'rack-test', '~> 0.5.4'
    s.add_development_dependency 'rake',      '~> 0.8.7'
    s.add_development_dependency 'rcov',      '~> 0.9.8'
    s.add_development_dependency 'rr',        '~> 0.10.11'
    s.add_development_dependency 'rspec',     '~> 2.0.0'

    s.add_dependency 'eventmachine'
    s.add_dependency 'heroku', '~> 1.9'
    s.add_dependency 'rack',   '~> 1.0'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
end
