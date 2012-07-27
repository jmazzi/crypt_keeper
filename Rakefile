#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'appraisal'

RSpec::Core::RakeTask.new :spec
Bundler::GemHelper.install_tasks

task :default => [:spec]
