#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'active_record'
require 'rspec/core/rake_task'
require 'appraisal'
require 'pg'

RSpec::Core::RakeTask.new :spec
Bundler::GemHelper.install_tasks

task :default => [:spec]

namespace :db do
  desc "Loads the database configuration from database yml."
  task :load_config do
    ActiveRecord::Tasks::DatabaseTasks.root = File.dirname(__FILE__)
    ActiveRecord::Base.configurations = YAML.load_file("#{File.dirname(__FILE__)}/spec/database.yml") || {}
  end

  desc "Creates the database from activerecord base configuration."
  task create: [:load_config] do
    ActiveRecord::Base.configurations.each do |adapter, config|
      ActiveRecord::Tasks::DatabaseTasks.create_current(adapter)
      if adapter == 'postgres'
        conn = PG::Connection.open(dbname: config['database'])
        conn.exec('CREATE EXTENSION IF NOT EXISTS pgcrypto')
      end
    end
  end
end
