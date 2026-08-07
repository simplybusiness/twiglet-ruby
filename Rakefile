require 'rake/testtask'
require 'bundler/gem_tasks'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test_coverage.rb', 'test/*_test.rb', 'examples/rack/request_logger_test.rb']
  t.verbose = true
end

desc 'Validate RBS type signatures'
task :rbs do
  sh 'bundle exec rbs -I sig -r logger -r json -r time validate'
end

task default: :test
