# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/twiglet/validator'

describe Twiglet::Validator do
  let(:valid)

  before do
    schema = {
      "type"=>"object",
      "required" => ["message"],
      "properties" => {
        "message" => {
          "type" => "string"
        }
      }
    }

    @validator = Twiglet::Validator.new(schema)
  end

  it 'is a no-op when validation passes' do
    assert_nil(
      @validator.validate({ message: 'this is my message', foo: 'bar' }) do
        raise 'I will throw this error if validation fails'
      end
    )
  end

  it 'executes the block provided when validation fails' do
    assert_raises 'I will throw this error if validation fails' do
      @validator.validate({ message: true }) do
        raise 'I will throw this error if validation fails'
      end
    end
  end

  it 'is a no-op when validation fails but no block is provided' do
    assert_nil(
      @validator.validate({ message: true })
    )
  end
end
