# frozen_string_literal: true

require 'json-schema'
require 'json'

module Twiglet
  class Validator
    def initialize(schema)
      @schema = schema
    end

    def self.from_file(file_path)
      new(JSON.parse(File.read(file_path)))
    end

    def validate(message, &block)
      return unless block_given?

      yield unless JSON::Validator.validate(@schema, message)
    end
  end
end
