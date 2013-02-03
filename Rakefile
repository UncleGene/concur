#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Concur::Application.load_tasks

Rake::TestTask.new(:spec) do |t|
  t.libs << 'lib'
  t.libs << 'spec'
  t.pattern = "spec/**/#{ENV['for'] || '*'}_spec.rb"
  t.verbose = true
end
