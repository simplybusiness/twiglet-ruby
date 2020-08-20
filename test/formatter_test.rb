# frozen_string_literal: true

require 'minitest/autorun'
require 'json'
require_relative '../lib/twiglet/formatter'

describe Twiglet::Formatter do
  before do
    @now = -> { Time.utc(2020, 5, 11, 15, 1, 1) }
    @formatter = Twiglet::Formatter.new('petshop', now: @now)
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

  describe Twiglet::Formatter::MessageStrToLogObj do
    it 'converts string message to hash representation' do
      msg = 'desired message string'
      assert_equal Twiglet::Formatter::MessageStrToLogObj.call(msg), {message: 'desired message string'}
    end

    it 'raises an error when empty message is given' do
      err = assert_raises RuntimeError, 'aa' do
        Twiglet::Formatter::MessageStrToLogObj.call('')
      end
      assert_equal err.message, 'The \'message\' property of log object must not be empty'
    end

    it 'raises an error when given message contains whitespaces only' do
      err = assert_raises RuntimeError, 'aa' do
        Twiglet::Formatter::MessageStrToLogObj.call(" \n\t ")
      end
      assert_equal err.message, 'The \'message\' property of log object must not be empty'
    end
  end
end
