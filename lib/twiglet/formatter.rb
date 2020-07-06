require 'logger'
require_relative '../hash_extensions'

module Twiglet
  class Formatter < ::Logger::Formatter
    Hash.include HashExtensions

    def initialize(service_name,
                   default_properties: {},
                   now: -> { Time.now.utc })
      @service_name = service_name
      @now = now
      @default_properties = default_properties

      super()
    end

    def call(severity, _time, _progname, msg)
      level = severity.downcase
      log(level: level, message: msg)
    end

    private

    def log(level:, message:)
      case message
      when String
        log_text(level, message: message)
      when Hash
        log_object(level, message: message)
      else
        raise('Message must be String or Hash')
      end
    end

    def log_text(level, message:)
      raise('The \'message\' property of log object must not be empty') if message.strip.empty?

      message = { message: message }
      log_message(level, message: message)
    end

    def log_object(level, message:)
      message = message.transform_keys(&:to_sym)
      message.key?(:message) || raise('Log object must have a \'message\' property')
      message[:message].strip.empty? && raise('The \'message\' property of log object must not be empty')

      log_message(level, message: message)
    end

    def log_message(level, message:)
      base_message = {
        "@timestamp": @now.call.iso8601(3),
        service: {
          name: @service_name
        },
        log: {
          level: level
        }
      }

      base_message
        .deep_merge(@default_properties.to_nested)
        .deep_merge(message.to_nested)
        .to_json
        .concat("\n")
    end
  end
end
