require "bundler/gem_tasks"
require 'rake/testtask'

desc 'Run tests'
task :test do
  Rake::TestTask.new do |t|
    t.libs << "test"
    t.libs << "lib"
    t.test_files = FileList['test/**/*_test.rb']
    t.verbose = true
  end
end

task :default => :test
