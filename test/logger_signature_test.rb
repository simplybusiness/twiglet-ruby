require 'minitest/autorun'
require 'rbs'
require 'rbs/unit_test'
require 'stringio'
require_relative '../lib/twiglet/logger'

class LoggerSignatureTest < Minitest::Test
  include RBS::UnitTest::TypeAssertions

  LEVELS = [:debug, :info, :warn, :error].freeze

  # TypeAssertions' own env loads libraries by name only, not our sig/ directory.
  def self.env
    @env ||= begin
      loader = RBS::EnvironmentLoader.new
      ['logger', 'json', 'time'].each { |lib| loader.add(library: lib, version: nil) }
      loader.add(path: Pathname(File.expand_path('../sig', __dir__)))
      RBS::Environment.from_loader(loader).resolve_type_names
    end
  end

  testing '::Twiglet::Logger'

  def test_levels_accept_a_hash
    LEVELS.each do |level|
      assert_send_type '(Hash[Symbol, untyped]) -> true', logger, level, { message: 'hi', event: { action: 'x' } }
    end
  end

  def test_levels_accept_a_string
    LEVELS.each { |level| assert_send_type '(String) -> true', logger, level, 'hi' }
  end

  def test_levels_accept_an_exception
    LEVELS.each { |level| assert_send_type '(StandardError) -> true', logger, level, StandardError.new('boom') }
  end

  def test_error_accepts_a_hash_and_an_exception
    assert_send_type '(Hash[Symbol, untyped], StandardError) -> true',
                     logger, :error, { message: 'failed' }, StandardError.new('boom')
  end

  private

  def logger
    Twiglet::Logger.new('svc', output: StringIO.new)
  end
end
