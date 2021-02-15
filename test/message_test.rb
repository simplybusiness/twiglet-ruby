require 'minitest/autorun'
require_relative '../lib/twiglet/message'

describe Twiglet::Message do
  it 'returns a message hash from a string' do
    assert_equal Twiglet::Message.new('hello, world'), { message: 'hello, world' }
  end

  it 'returns a message hash with symbolized keys' do
    input_message = { 'key' => 'value', 'message' => 'hello, world' }
    assert_equal Twiglet::Message.new(input_message), { key: 'value', message: 'hello, world' }
  end
end
