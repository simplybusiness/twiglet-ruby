require 'minitest/autorun'
require_relative '../lib/twiglet/message'

describe Twiglet::Message do
  it 'raises if message is empty' do
    assert_raises RuntimeError do
      Twiglet::Message.new('   ')
    end
  end

  it 'raises if message is not provided' do
    assert_raises RuntimeError do
      Twiglet::Message.new(foo: 'bar')
    end
  end

  it 'raises on unrecognized inputs' do
    assert_raises RuntimeError do
      Twiglet::Message.new(OpenStruct.new(message: 'hello'))
    end
  end

  describe '#format' do
    it 'returns a message hash from a string' do
      assert_equal Twiglet::Message.format('hello, world'), { message: 'hello, world' }
    end

    it 'returns a message hash with symbolized keys' do
      input_message = { 'key' => 'value', 'message' => 'hello, world' }
      assert_equal Twiglet::Message.format(input_message), { key: 'value', message: 'hello, world' }
    end
  end
end
