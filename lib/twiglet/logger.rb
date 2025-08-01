# frozen_string_literal: true

require 'logger'
require 'time'
require_relative 'formatter'
require_relative '../hash_extensions'
require_relative 'message'
require_relative 'validator'
require_relative 'error_serialiser'

module Twiglet
  class Logger < ::Logger
    Hash.include HashExtensions
    DEFAULT_VALIDATION_SCHEMA = File.read("#{__dir__}/validation_schema.json")

    def initialize(
      service_name,
      **args
    )
      @service_name = service_name
      @args = args

      now = args.fetch(:now, -> { Time.now.utc })
      output = args.fetch(:output, $stdout)
      level = args.fetch(:level, INFO)
      schema = args.fetch(:validation_schema, DEFAULT_VALIDATION_SCHEMA)

      raise 'Service name is mandatory' \
        unless service_name.is_a?(String) && !service_name.strip.empty?

      @validator = Validator.new(schema)

      formatter = Twiglet::Formatter.new(
        service_name,
        default_properties: args.fetch(:default_properties, {}),
        context_providers: Array(args[:context_provider] || args[:context_providers]),
        now: now,
        validator: @validator
      )
      super(output, formatter: formatter, level: level)
    end

    def configure_validation_error_response(&block)
      @validator.custom_error_handler = block
    end

    def debug(message_or_error = nil, &)
      message = message_or_error.is_a?(Exception) ? error_message(message_or_error) : message_or_error

      super(message, &)
    end

    def info(message_or_error = nil, &)
      message = message_or_error.is_a?(Exception) ? error_message(message_or_error) : message_or_error

      super(message, &)
    end

    def warn(message_or_error = nil, &)
      message = message_or_error.is_a?(Exception) ? error_message(message_or_error) : message_or_error

      super(message, &)
    end

    def error(message_or_error = nil, error = nil, &)
      message = if error
                  error_message(error, message_or_error)
                elsif message_or_error.is_a?(Exception)
                  error_message(message_or_error)
                else
                  message_or_error
                end

      super(message, &)
    end

    def with(default_properties)
      self.class.new(
        @service_name,
        **@args, default_properties: default_properties
      )
    end

    def validation_schema(validation_schema)
      self.class.new(
        @service_name,
        **@args, validation_schema: validation_schema
      )
    end

    def context_provider(&blk)
      new_context_providers = Array(@args[:context_providers])
      new_context_providers << blk

      self.class.new(
        @service_name,
        **@args, context_providers: new_context_providers
      )
    end

    alias_method :warning, :warn
    alias_method :critical, :fatal

    private

    def error_message(error, message = nil)
      error_hash = Twiglet::ErrorSerialiser.new.serialise_error(error)
      message = error.message if message.nil? || message.empty?
      Message.new(message).merge(error_hash)
    end
  end
end
