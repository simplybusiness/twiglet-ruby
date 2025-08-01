# frozen_string_literal: true

require 'json-schema'
require 'json'

module Twiglet
  class Validator
    attr_accessor :custom_error_handler

    def initialize(schema)
      @schema = JSON.parse(schema)
      @custom_error_handler = ->(e) { raise e }
      @validator = JSON::Validator.new(@schema)
    end

    def validate(message)
      @validator.validate(message)
    rescue JSON::Schema::ValidationError => e
      custom_error_handler.call(e)
    end
  end
end
