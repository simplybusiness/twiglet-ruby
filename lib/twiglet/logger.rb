# frozen_string_literal: true

require 'logger'
require 'time'
require_relative 'formatter'
require_relative '../hash_extensions'
require_relative 'message'
require_relative 'validator'

module Twiglet
  class Logger < ::Logger
    Hash.include HashExtensions

    def initialize(
      service_name,
      **args
    )
      @service_name = service_name
      default_properties = args.delete(:default_properties) || {}
      @args = args

      now = args.fetch(:now, -> { Time.now.utc })
      output = args.fetch(:output, $stdout)
      level = args.fetch(:level, Logger::DEBUG)
      validation_schema = args.fetch(:validation_schema, File.read("#{__dir__}/validation_schema.json"))

      raise 'Service name is mandatory' \
        unless service_name.is_a?(String) && !service_name.strip.empty?

      @validator = Validator.new(validation_schema)

      formatter = Twiglet::Formatter.new(
        service_name,
        default_properties: default_properties,
        now: now,
        validator: @validator
      )
      super(output, formatter: formatter, level: level)
    end

    def configure_validation_error_response(&block)
      @validator.custom_error_handler = block
    end

    def error(message = nil, error = nil, &block)
      if error
        error_fields = {
          error: {
            type: error.class,
            message: error.message
          }
        }
        add_stack_trace(error_fields, error)
        message = Message.new(message).merge(error_fields)
      end

      super(message, &block)
    end

    def with(default_properties)
      Logger.new(
        @service_name,
        **@args.merge(default_properties: default_properties)
      )
    end

    alias_method :warning, :warn
    alias_method :critical, :fatal

    private

    def add_stack_trace(hash_to_add_to, error)
      hash_to_add_to[:error][:stack_trace] = error.backtrace.join("\n") if error.backtrace
    end
  end
end
