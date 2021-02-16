# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/twiglet/validator'

describe Twiglet::Validator do
  let(:valid)

  before do
    schema = {
      "type" => "object",
      "required" => ["message"],
      "properties" => {
        "message" => {
          "type" => "string"
        }
      }
    }

    @validator = Twiglet::Validator.new(schema.to_json)
  end

  it 'does not raise when validation passes' do
    assert_equal(@validator.validate({ message: 'this is my message', foo: 'bar' }), true)
  end

  it 'raises when validation fails' do
    assert_raises JSON::Schema::ValidationError do
      @validator.validate({ message: true })
    end
  end

  it 'is a no-op when validator is configured to swallow errors' do
    @validator.custom_error_handler = ->(e) { puts e }

    assert_nil(@validator.validate({ message: true }))
  end
end
