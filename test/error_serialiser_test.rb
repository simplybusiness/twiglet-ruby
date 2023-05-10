# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/mock'
require_relative '../lib/twiglet/error_serialiser'

describe Twiglet::ErrorSerialiser do

  describe 'logging an exception' do
    it 'should log an error with backtrace' do

      begin
        1 / 0
      rescue StandardError => e
        error_hash = Twiglet::ErrorSerialiser.new.serialise_error(e)
        assert_equal 'divided by 0', error_hash[:error][:message]
        assert_equal 'ZeroDivisionError', error_hash[:error][:type]
        assert_match 'test/error_serialiser_test.rb', error_hash[:error][:stack_trace].first
      end
    end
  end
end
