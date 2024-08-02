# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/mock'
require_relative '../lib/twiglet/logger'
require 'active_support'

LEVELS = [
  { method: :debug, level: 'debug' },
  { method: :info, level: 'info' },
  { method: :warning, level: 'warn' },
  { method: :warn, level: 'warn' },
  { method: :critical, level: 'fatal' },
  { method: :fatal, level: 'fatal' },
  { method: :error, level: 'error' }
].freeze

# rubocop:disable Metrics/BlockLength
describe Twiglet::Logger do
  before do
    @now = -> { Time.utc(2020, 5, 11, 15, 1, 1) }
    @buffer = StringIO.new
    @logger = Twiglet::Logger.new(
      'petshop',
      now: @now,
      output: @buffer
    )
  end

  it 'should throw an error with an empty service name' do
    assert_raises RuntimeError do
      Twiglet::Logger.new('  ')
    end
  end

  it 'conforms to the standard Ruby Logger API' do
    [
      :debug,
      :debug?,
      :info,
      :info?,
      :warn,
      :warn?,
      :fatal,
      :fatal?,
      :error,
      :error?,
      :level,
      :level=,
      :sev_threshold=
    ].each do |call|
      assert @logger.respond_to?(call), "Logger does not respond to #{call}"
    end
  end

  describe 'JSON logging' do
    it 'should throw an error with an empty message' do
      assert_raises JSON::Schema::ValidationError, "The property '#/message' was not of a minimum string length of 1" do
        @logger.info({ message: '' })
      end
    end

    it 'should throw an error if message is missing' do
      assert_raises JSON::Schema::ValidationError, "The property '#/message' was not of a minimum string length of 1" do
        @logger.info({ foo: 'bar' })
      end
    end

    it 'should log mandatory attributes' do
      @logger.error({ message: 'Out of pets exception' })
      actual_log = read_json(@buffer)

      expected_log = {
        message: 'Out of pets exception',
        ecs: {
          version: '1.5.0'
        },
        '@timestamp': '2020-05-11T15:01:01.000Z',
        service: {
          name: 'petshop'
        },
        log: {
          level: 'error'
        }
      }

      assert_equal expected_log, actual_log
    end

    it 'should log the provided message' do
      @logger.error(
        {
          event:
                                 { action: 'exception' },
          message: 'Emergency! Emergency!'
        }
      )
      log = read_json(@buffer)

      assert_equal 'exception', log[:event][:action]
      assert_equal 'Emergency! Emergency!', log[:message]
    end

    it 'should log scoped properties defined at creation' do
      extra_properties = {
        trace: {
          id: '1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb'
        },
        service: {
          type: 'shop'
        },
        request: { method: 'get' },
        response: { status_code: 200 }
      }

      output = StringIO.new
      logger = Twiglet::Logger.new(
        'petshop',
        now: @now,
        output: output,
        default_properties: extra_properties
      )

      logger.error({ message: 'GET /cats' })
      log = read_json output

      assert_equal '1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb', log[:trace][:id]
      assert_equal 'petshop', log[:service][:name]
      assert_equal 'shop', log[:service][:type]
      assert_equal 'get', log[:request][:method]
      assert_equal 200, log[:response][:status_code]
    end

    it "should be able to add properties with '.with'" do
      # Let's add some context to this customer journey
      purchase_logger = @logger.with(
        {
          trace: { id: '1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb' },
          customer: { full_name: 'Freda Bloggs' },
          event: { action: 'pet purchase' }
        }
      )

      # do stuff
      purchase_logger.info(
        {
          message: 'customer bought a dog',
          pet: { name: 'Barker', species: 'dog', breed: 'Bitsa' }
        }
      )

      log = read_json @buffer

      assert_equal '1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb', log[:trace][:id]
      assert_equal 'Freda Bloggs', log[:customer][:full_name]
      assert_equal 'pet purchase', log[:event][:action]
      assert_equal 'customer bought a dog', log[:message]
      assert_equal 'Barker', log[:pet][:name]
    end

    it "isn't possible to chain .with methods to gradually add messages" do
      # Let's add some context to this customer journey
      purchase_logger = @logger.with(
        {
          trace: { id: '1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb' }
        }
      ).with(
        {
          customer: { full_name: 'Freda Bloggs' },
          event: { action: 'pet purchase' }
        }
      )

      # do stuff
      purchase_logger.info(
        {
          message: 'customer bought a dog',
          pet: { name: 'Barker', species: 'dog', breed: 'Bitsa' }
        }
      )

      log = read_json @buffer

      assert_nil log[:trace]
      assert_equal 'Freda Bloggs', log[:customer][:full_name]
      assert_equal 'pet purchase', log[:event][:action]
      assert_equal 'customer bought a dog', log[:message]
      assert_equal 'Barker', log[:pet][:name]
    end

    it "should be able to add contextual information to events with the context_provider" do
      purchase_logger = @logger.context_provider do
        { 'context' => { 'id' => 'my-context-id' } }
      end

      # do stuff
      purchase_logger.info(
        {
          message: 'customer bought a dog',
          pet: { name: 'Barker', species: 'dog', breed: 'Bitsa' }
        }
      )

      log = read_json @buffer

      assert_equal 'customer bought a dog', log[:message]
      assert_equal 'my-context-id', log[:context][:id]
    end

    it "chaining .with and .context_provider is possible" do
      # Let's add some context to this customer journey
      purchase_logger = @logger.with(
        {
          trace: { id: '1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb' },
          customer: { full_name: 'Freda Bloggs' },
          event: { action: 'pet purchase' }
        }
      ).context_provider do
        { 'context' => { 'id' => 'my-context-id' } }
      end

      # do stuff
      purchase_logger.info(
        {
          message: 'customer bought a dog',
          pet: { name: 'Barker', species: 'dog', breed: 'Bitsa' }
        }
      )

      log = read_json @buffer

      assert_equal '1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb', log[:trace][:id]
      assert_equal 'Freda Bloggs', log[:customer][:full_name]
      assert_equal 'pet purchase', log[:event][:action]
      assert_equal 'customer bought a dog', log[:message]
      assert_equal 'Barker', log[:pet][:name]
      assert_equal 'my-context-id', log[:context][:id]
    end

    it "chaining .context_provider and .with is possible" do
      # Let's add some context to this customer journey
      purchase_logger = @logger
                        .context_provider do
        { 'context' => { 'id' => 'my-context-id' } }
      end.with(
        {
          trace: { id: '1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb' },
          customer: { full_name: 'Freda Bloggs' },
          event: { action: 'pet purchase' }
        }
      )
      # do stuff
      purchase_logger.info(
        {
          message: 'customer bought a dog',
          pet: { name: 'Barker', species: 'dog', breed: 'Bitsa' }
        }
      )

      log = read_json @buffer

      assert_equal '1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb', log[:trace][:id]
      assert_equal 'Freda Bloggs', log[:customer][:full_name]
      assert_equal 'pet purchase', log[:event][:action]
      assert_equal 'customer bought a dog', log[:message]
      assert_equal 'Barker', log[:pet][:name]
      assert_equal 'my-context-id', log[:context][:id]
    end

    it "previously supplied context providers should be preserved" do
      # Let's add some context to this customer journey
      purchase_logger = @logger
                        .context_provider { { 'first-context' => { 'first-id' => 'my-first-context-id' } } }
                        .context_provider { { 'second-context' => { 'second-id' => 'my-second-context-id' } } }
      # do stuff
      purchase_logger.info(
        {
          message: 'customer bought a dog',
          pet: { name: 'Barker', species: 'dog', breed: 'Bitsa' }
        }
      )

      log = read_json @buffer

      assert_equal 'customer bought a dog', log[:message]
      assert_equal 'Barker', log[:pet][:name]
      assert_equal 'my-first-context-id', log[:'first-context'][:'first-id']
      assert_equal 'my-second-context-id', log[:'second-context'][:'second-id']
    end

    it "should log 'message' string property" do
      message = {}
      message['message'] = 'Guinea pigs arrived'
      @logger.debug(message)
      log = read_json(@buffer)

      assert_equal 'Guinea pigs arrived', log[:message]
    end

    it "should log multiple messages properly" do
      @logger.debug({ message: 'hi' })
      @logger.info({ message: 'there' })

      expected_output =
        '{"ecs":{"version":"1.5.0"},"@timestamp":"2020-05-11T15:01:01.000Z",' \
        '"service":{"name":"petshop"},"log":{"level":"debug"},"message":"hi"}' \
        "\n" \
        '{"ecs":{"version":"1.5.0"},"@timestamp":"2020-05-11T15:01:01.000Z",' \
        '"service":{"name":"petshop"},"log":{"level":"info"},"message":"there"}' \
        "\n" \

      assert_equal expected_output, @buffer.string
    end

    it 'should work with mixed string and symbol properties' do
      log = {
        'trace.id': '1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb'
      }
      event = {}
      log['event'] = event
      log['message'] = 'customer bought a dog'
      pet = {}
      pet['name'] = 'Barker'
      pet['breed'] = 'Bitsa'
      pet[:species] = 'dog'
      log[:pet] = pet

      @logger.debug(log)
      actual_log = read_json(@buffer)

      assert_equal '1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb', actual_log[:trace][:id]
      assert_equal 'customer bought a dog', actual_log[:message]
      assert_equal 'Barker', actual_log[:pet][:name]
      assert_equal 'dog', actual_log[:pet][:species]
      assert_equal 'Bitsa', actual_log[:pet][:breed]
    end

    LEVELS.each do |attrs|
      it "should correctly log level when calling #{attrs[:method]}" do
        @logger.public_send(attrs[:method], { message: 'a log message' })
        actual_log = read_json(@buffer)

        assert_equal attrs[:level], actual_log[:log][:level]
        assert_equal 'a log message', actual_log[:message]
      end
    end
  end

  describe 'logging an exception' do
    it 'should log an error with backtrace' do
      begin
        1 / 0
      rescue StandardError => e
        @logger.error({ message: 'Artificially raised exception' }, e)
      end

      actual_log = read_json(@buffer)

      assert_equal 'Artificially raised exception', actual_log[:message]
      assert_equal 'ZeroDivisionError', actual_log[:error][:type]
      assert_equal 'divided by 0', actual_log[:error][:message]
      assert_match 'test/logger_test.rb', actual_log[:error][:stack_trace].first
    end

    it 'should log an error without backtrace' do
      e = StandardError.new('Connection timed-out')
      @logger.error({ message: 'Artificially raised exception' }, e)

      actual_log = read_json(@buffer)

      assert_equal 'Artificially raised exception', actual_log[:message]
      assert_equal 'StandardError', actual_log[:error][:type]
      assert_equal 'Connection timed-out', actual_log[:error][:message]
      refute actual_log[:error].key?(:stack_trace)
    end

    it 'should log an error with string message' do
      e = StandardError.new('Some error')
      @logger.error('Artificially raised exception with string message', e)

      actual_log = read_json(@buffer)

      assert_equal 'Artificially raised exception with string message', actual_log[:message]
      assert_equal 'StandardError', actual_log[:error][:type]
      assert_equal 'Some error', actual_log[:error][:message]
    end

    it 'should log an error if no message is given' do
      e = StandardError.new('Some error')
      @logger.error(e)

      actual_log = read_json(@buffer)

      assert_equal 'Some error', actual_log[:message]
      assert_equal 'StandardError', actual_log[:error][:type]
      assert_equal 'Some error', actual_log[:error][:message]
    end

    it 'should log an error if nil message is given' do
      e = StandardError.new('Some error')
      @logger.error(nil, e)

      actual_log = read_json(@buffer)

      assert_equal 'Some error', actual_log[:message]
      assert_equal 'StandardError', actual_log[:error][:type]
      assert_equal 'Some error', actual_log[:error][:message]
    end

    it 'should log a string if no error is given' do
      @logger.error('Some error')

      actual_log = read_json(@buffer)

      assert_equal 'Some error', actual_log[:message]
    end

    it 'should log error type properly even when active_support is required' do
      e = StandardError.new('Unknown error')
      @logger.error('Artificially raised exception with string message', e)

      actual_log = read_json(@buffer)

      assert_equal 'StandardError', actual_log[:error][:type]
    end

    [:debug, :info, :warn].each do |level|
      it "can log an error with type, error message etc.. as '#{level}'" do
        error_message = "error to be logged as #{level}"
        e = StandardError.new(error_message)
        @logger.public_send(level, e)

        actual_log = read_json(@buffer)

        assert_equal error_message, actual_log[:message]
        assert_equal 'StandardError', actual_log[:error][:type]
        assert_equal error_message, actual_log[:error][:message]
      end
    end
  end

  describe 'text logging' do
    it 'should throw an error with an empty message' do
      assert_raises JSON::Schema::ValidationError, "The property '#/message' was not of a minimum string length of 1" do
        @logger.info('')
      end
    end

    it 'should log mandatory attributes' do
      @logger.error('Out of pets exception')
      actual_log = read_json(@buffer)

      expected_log = {
        message: 'Out of pets exception',
        ecs: {
          version: '1.5.0'
        },
        '@timestamp': '2020-05-11T15:01:01.000Z',
        service: {
          name: 'petshop'
        },
        log: {
          level: 'error'
        }
      }

      assert_equal expected_log, actual_log
    end

    it 'should log the provided message' do
      @logger.error('Emergency! Emergency!')
      log = read_json(@buffer)

      assert_equal 'Emergency! Emergency!', log[:message]
    end

    LEVELS.each do |attrs|
      it "should correctly log level when calling #{attrs[:method]}" do
        @logger.public_send(attrs[:method], 'a log message')
        actual_log = read_json(@buffer)

        assert_equal attrs[:level], actual_log[:log][:level]
        assert_equal 'a log message', actual_log[:message]
      end
    end
  end

  describe 'logging with a block' do
    LEVELS.each do |attrs|
      it "should correctly log the block when calling #{attrs[:method]}" do
        block = proc { 'a block log message' }
        @logger.public_send(attrs[:method], &block)
        actual_log = read_json(@buffer)

        assert_equal attrs[:level], actual_log[:log][:level]
        assert_equal 'a block log message', actual_log[:message]
      end
    end

    it 'should ignore the given progname if a block is also given' do
      block = proc { 'a block log message' }
      @logger.info('my-program-name', &block)
      actual_log = read_json(@buffer)

      assert_equal 'info', actual_log[:log][:level]
      assert_equal 'a block log message', actual_log[:message]
    end
  end

  describe 'dotted keys' do
    it 'should be able to convert dotted keys to nested objects' do
      @logger.debug(
        {
          'trace.id': '1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb',
          message: 'customer bought a dog',
          'pet.name': 'Barker',
          'pet.species': 'dog',
          'pet.breed': 'Bitsa'
        }
      )
      log = read_json(@buffer)

      assert_equal '1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb', log[:trace][:id]
      assert_equal 'customer bought a dog', log[:message]
      assert_equal 'Barker', log[:pet][:name]
      assert_equal 'dog', log[:pet][:species]
      assert_equal 'Bitsa', log[:pet][:breed]
    end

    it 'should be able to mix dotted keys and nested objects' do
      @logger.debug(
        {
          'trace.id': '1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb',
          message: 'customer bought a dog',
          pet: { name: 'Barker', breed: 'Bitsa' },
          'pet.species': 'dog'
        }
      )
      log = read_json(@buffer)

      assert_equal '1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb', log[:trace][:id]
      assert_equal 'customer bought a dog', log[:message]
      assert_equal 'Barker', log[:pet][:name]
      assert_equal 'dog', log[:pet][:species]
      assert_equal 'Bitsa', log[:pet][:breed]
    end
  end

  describe 'logger level' do
    [
      { expression: :info, level: 1 },
      { expression: 'warn', level: 2 },
      { expression: Logger::DEBUG, level: 0 }
    ].each do |args|
      it "sets the severity threshold to level #{args[:level]}" do
        @logger.level = args[:expression]
        assert_equal args[:level], @logger.level
      end
    end

    it 'initializes the logger with the provided level' do
      assert_equal Logger::WARN, Twiglet::Logger.new('petshop', level: :warn).level
    end

    it 'does not log lower level' do
      logger = Twiglet::Logger.new(
        'petshop',
        now: @now,
        output: @buffer,
        level: Logger::INFO
      )
      logger.debug({ name: 'Davis', best_boy_or_girl?: true, species: 'dog' })
      assert_empty @buffer.read
    end
  end

  describe 'configuring error response' do
    it 'blows up by default' do
      assert_raises JSON::Schema::ValidationError,
                    "The property '#/message' of type boolean did not match the following type: string" do
        @logger.debug(message: true)
      end
    end

    it 'silently swallows errors when configured to do so' do
      mock = Minitest::Mock.new

      @logger.configure_validation_error_response do |_e|
        mock.notify_error("Logging schema validation error")
      end

      mock.expect(:notify_error, nil, ["Logging schema validation error"])
      nonconformant_log = { message: true }
      @logger.debug(nonconformant_log)
    end
  end

  describe 'validation schema' do
    before do
      validation_schema = <<-JSON
        {
          "type": "object",
          "required": ["pet"],
          "properties": {
            "pet": {
              "type": "object",
              "required": ["name", "best_boy_or_girl?"],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "best_boy_or_girl?": {
                  "type": "boolean"
                }
              }
            }
          }
        }
      JSON

      @logger = Twiglet::Logger.new(
        'petshop',
        now: @now,
        output: @buffer,
        validation_schema: validation_schema
      )
    end

    it 'allows for the configuration of custom validation rules' do
      @logger.debug(
        {
          pet: { name: 'Davis', best_boy_or_girl?: true, species: 'dog' }
        }
      )
      log = read_json(@buffer)

      assert_equal true, log[:pet][:best_boy_or_girl?]
    end

    it 'raises when custom validation rules are broken' do
      nonconformant = {
        pet: { name: 'Davis' }
      }

      assert_raises JSON::Schema::ValidationError,
                    "The property '#/pet' did not contain a required property of 'best_boy_or_girl?'" do
        @logger.debug(nonconformant)
      end
    end
  end

  private

  def read_json(buffer)
    buffer.rewind
    JSON.parse(buffer.read, symbolize_names: true)
  end
end
# rubocop:enable Metrics/BlockLength
