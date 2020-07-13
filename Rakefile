require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb', 'examples/rack/request_logger_test.rb']
  t.verbose = true
end
