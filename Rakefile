require "bundler/gem_tasks"
require 'rake/testtask'

desc 'Run mysql2 and postgresql test'
task :test do
  Rake::Task["test:mysql2"].invoke
  Rake::Task["test:postgresql"].invoke
end

namespace :test do
  %w(mysql2 postgresql).each do |db|
    Rake::TestTask.new(db) do |t|
      t.libs << "test"
      t.libs << "lib"
      t.test_files = FileList["test/config/prepare_#{db}", 'test/**/*_test.rb']
      t.verbose = false
      t.warning = false
    end
  end
end

task :default => :test
