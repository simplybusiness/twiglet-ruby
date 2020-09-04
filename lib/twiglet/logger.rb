# frozen_string_literal: true

require 'logger'
require 'time'
require 'json'
require_relative 'formatter'
require_relative '../hash_extensions'
require_relative 'message'

module Twiglet
  class Logger < ::Logger
    Hash.include HashExtensions

    def initialize(
      service_name,
      default_properties: {},
      now: -> { Time.now.utc },
      output: $stdout,
      level: Logger::DEBUG
    )
      @service_name = service_name
      @now = now
      @output = output
      @level = level

      raise 'Service name is mandatory' \
        unless service_name.is_a?(String) && !service_name.strip.empty?

      formatter = Twiglet::Formatter.new(service_name, default_properties: default_properties, now: now)
      super(output, formatter: formatter, level: level)
    end

    def error(message = nil, error = nil, &block)
      if error
        error_fields = {
          'error': {
            'type': error.class,
            'message': error.message
          }
        }
        add_stack_trace(error_fields, error)
        message = Message.new(message).merge(error_fields)
      end

      super(message, &block)
    end

    def with(default_properties)
      Logger.new(@service_name,
                 default_properties: default_properties,
                 now: @now,
                 output: @output,
                 level: @level)
    end

    alias_method :warning, :warn
    alias_method :critical, :fatal

    private

    def add_stack_trace(hash_to_add_to, error)
      hash_to_add_to[:error][:stack_trace] = error.backtrace.join("\n") if error.backtrace
    end
  end
end
