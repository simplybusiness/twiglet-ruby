require 'simplecov'
require 'simplecov-cobertura'

SimpleCov.start do
  add_filter "/test/"
  add_filter "examples/rack/request_logger_test.rb"

  if ENV['CI']
    formatter SimpleCov::Formatter::MultiFormatter.new(
      [
        SimpleCov::Formatter::SimpleFormatter,
        SimpleCov::Formatter::CoberturaFormatter
      ]
    )
  else
    formatter SimpleCov::Formatter::MultiFormatter.new(
      [
        SimpleCov::Formatter::SimpleFormatter,
        SimpleCov::Formatter::HTMLFormatter
      ]
    )
  end
end
