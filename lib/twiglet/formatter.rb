require 'logger'
require_relative '../hash_extensions'
require_relative 'message'

module Twiglet
  class Formatter < ::Logger::Formatter
    Hash.include HashExtensions

    def initialize(
      service_name,
      validator:,
      default_properties: {},
      context_provider: nil,
      now: -> { Time.now.utc }
    )
      @service_name = service_name
      @now = now
      @default_properties = default_properties
      @context_provider = context_provider
      @validator = validator

      super()
    end

    def call(severity, _time, _progname, msg)
      level = severity.downcase
      message = Message.new(msg)
      @validator.validate(message)
      log(level: level, message: message)
    end

    private

    def log(level:, message:)
      base_message = {
        ecs: {
          version: '1.5.0'
        },
        '@timestamp': @now.call.iso8601(3),
        service: {
          name: @service_name
        },
        log: {
          level: level
        }
      }

      context = @context_provider&.call || {}

      JSON.generate(
        base_message
          .deep_merge(@default_properties.to_nested)
          .deep_merge(context.to_nested)
          .deep_merge(message.to_nested)
      ).concat("\n")
    end
  end
end
