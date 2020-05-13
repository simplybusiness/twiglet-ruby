require 'date'
require 'json'
require_relative 'elastic_common_schema'

class Logger
  include ElasticCommonSchema

  def initialize(service:, now:, output:, scoped_properties: {})
    @service = service
    @now = now
    @output = output
    @scoped_properties = scoped_properties
  end

  def debug(message)
    log(level: "debug", message: message)
  end

  def info(message)
    log(level: "info", message: message)
  end

  def warning(message)
    log(level: "warning", message: message)
  end

  def error(message)
    log(level: "error", message: message)
  end

  def critical(message)
    log(level: "critical", message: message)
  end

  def with(scoped_properties)
    Logger.new(service: @service,
               now: @now,
               output: @output,
               scoped_properties: scoped_properties)
  end

  private

  def valid_string?(message)
    message.strip.length > 0
  end

  def log(level:, message:)
    case message
    when String
      raise "There must be a non-empty message" unless valid_string?(message)
      message = { message: message }
    when Hash
      message = message.transform_keys(&:to_sym)
      raise "Log object must have a 'message' property" unless message.key?(:message)
      raise "The 'message' property of log object must not be empty" unless valid_string?(message[:message])
    else
      raise "Message must be either an object or a string"
    end

    total_message = ({
        service: {
          name: @service
        },
        "@timestamp": @now.iso8601(3),
        log: {
          level: level
        }
      })
      .merge(@scoped_properties)
      .merge(message)
      .then { |log_entry| to_nested(log_entry) }

    @output.puts total_message.to_json
  end
  
end
