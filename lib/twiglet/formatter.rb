require 'logger'
require_relative '../hash_extensions'
require_relative 'message'

module Twiglet
  class Formatter < ::Logger::Formatter
    Hash.include HashExtensions

    def initialize(service_name,
                   **args)
      @service_name = service_name
      @now = args[:now]
      @default_properties = args[:default_properties]

      super()
    end

    def call(severity, _time, _progname, msg)
      level = severity.downcase
      log(level: level, message: Message.new(msg))
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
