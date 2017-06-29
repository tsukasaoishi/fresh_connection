require "bundler/gem_tasks"
require 'rake/testtask'

desc 'Run mysql2 and postgresql tests'
task :test do
  Rake::Task["test:mysql2"].invoke
  Rake::Task["test:postgresql"].invoke
end

namespace :test do
  %w(mysql2 postgresql).each do |test_name|
    Rake::TestTask.new(test_name) do |t|
      t.libs << "test"
      t.libs << "lib"
      t.test_files = FileList["test/config/prepare_#{test_name}", 'test/**/*_test.rb']
      t.verbose = true
    end
  end
end

task :default => :test
