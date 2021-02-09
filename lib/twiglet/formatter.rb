require 'logger'
require_relative '../hash_extensions'
require_relative 'message'
require_relative 'validator'

module Twiglet
  class Formatter < ::Logger::Formatter
    attr_accessor :validation_error_response

    Hash.include HashExtensions

    def initialize(service_name,
                   default_properties: {},
                   now: -> { Time.now.utc })
      @service_name = service_name
      @now = now
      @default_properties = default_properties
      @validation_error_response = ->(msg) { raise "Schema validation error for #{msg}" }

      @validator = Validator.from_file('lib/twiglet/validation_schema.json')

      super()
    end

    def call(severity, _time, _progname, msg)
      level = severity.downcase
      message = Message.new(msg)
      @validator.validate(message) do
        @validation_error_response.call(message)
      end
      log(level: level, message: message)
    end

    private

    def log(level:, message:)
      base_message = {
        ecs: {
          version: '1.5.0'
        },
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
