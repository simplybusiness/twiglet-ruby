require 'minitest/autorun'
require_relative '../lib/twiglet/message'

describe Twiglet::Message do
  it 'returns nil for a missing key when built from a string' do
    assert_nil Twiglet::Message.new('hello, world')[:missing]
  end

  it 'returns nil for a missing key when built from a non-string, non-hash value' do
    assert_nil Twiglet::Message.new(42)[:missing]
  end

  it 'returns a message hash from a string' do
    assert_equal Twiglet::Message.new('hello, world'), { message: 'hello, world' }
  end

  it 'returns a message hash with symbolized keys' do
    input_message = { 'key' => 'value', 'message' => 'hello, world' }
    assert_equal Twiglet::Message.new(input_message), { key: 'value', message: 'hello, world' }
  end

  it 'returns a message hash with symbolized keys from a frozen hash' do
    input_message = { 'key' => 'value', 'message' => 'hello, world' }.freeze
    assert_equal Twiglet::Message.new(input_message), { key: 'value', message: 'hello, world' }
  end

  it 'does not mutate the input hash' do
    input_message = { 'key' => 'value', 'message' => 'hello, world' }
    Twiglet::Message.new(input_message)
    assert_equal({ 'key' => 'value', 'message' => 'hello, world' }, input_message)
  end
end
