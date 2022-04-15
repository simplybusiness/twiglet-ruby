# frozen_string_literal: true

require 'minitest/autorun'
require 'json'
require_relative '../lib/twiglet/formatter'
require_relative '../lib/twiglet/validator'

describe Twiglet::Formatter do
  before do
    @now = -> { Time.utc(2020, 5, 11, 15, 1, 1) }
    @formatter = Twiglet::Formatter.new('petshop', now: @now, validator: Twiglet::Validator.new({}.to_json))
  end

  it 'initializes an instance of a Ruby Logger Formatter' do
    assert @formatter.is_a?(::Logger::Formatter)
  end

  it 'returns a formatted log from a string message' do
    msg = @formatter.call('warn', nil, nil, 'shop is running low on dog food')
    expected_log = {
      "ecs" => {
        "version" => '1.5.0'
      },
      "@timestamp" => '2020-05-11T15:01:01.000Z',
      "service" => {
        "name" => 'petshop'
      },
      "log" => {
        "level" => 'warn'
      },
      "message" => 'shop is running low on dog food'
    }
    assert_equal JSON.parse(msg), expected_log
  end

  it 'merges the outputs of the context provider into messages logs' do
    provider = -> { { 'request' => { 'id' => '1234567890' } } }
    formatter = Twiglet::Formatter.new(
      'petshop', now: @now, validator: Twiglet::Validator.new({}.to_json),
                 context_provider: provider
    )
    msg = formatter.call('warn', nil, nil, 'shop is running low on dog food')
    expected_log = {
      "ecs" => {
        "version" => '1.5.0'
      },
      "@timestamp" => '2020-05-11T15:01:01.000Z',
      "service" => {
        "name" => 'petshop'
      },
      "log" => {
        "level" => 'warn'
      },
      "message" => 'shop is running low on dog food',
      "request" => {
        'id' => '1234567890'
      }
    }
    assert_equal JSON.parse(msg), expected_log
  end
end
