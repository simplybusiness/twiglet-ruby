require 'minitest/autorun'
require_relative '../../lib/twiglet/logger'
require_relative './request_logger'
require 'rack'

describe RequestLogger do
  let(:output) { StringIO.new }

  before { output.rewind }

  it 'log should not be empty' do
    request.get("/some/path")
    log = output.string
    refute_empty log
  end

  it 'logs the request data' do
    request.get("/some/path?some_var=1", 'HTTP_ACCEPT' => 'application/json',
                                         'REMOTE_ADDR' => '0.0.0.0',
                                         'HTTP_VERSION' => 'HTTP/1.1',
                                         'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh)')
    log = JSON.parse(output.string)

    expected_log = {
      "log" => { "level" => "info" },
      "http" => {
        "request" => {
          "method" => "GET",
          "mime_type" => 'application/json'
        },
        "response" => {
          "status" => 200
        },
        "version" => 'HTTP/1.1'
      },
      "url" => {
        "path" => "/some/path",
        "query" => "some_var=1",
        "domain" => "example.org"
      },
      "client" => {
        'ip' => '0.0.0.0'
      },
      "user_agent" => {
        "original" => 'Mozilla/5.0 (Macintosh)'
      },
      "message" => "GET: /some/path"
    }

    assert_equal(log['log'], expected_log['log'])
    assert_equal(log['http'], expected_log['http'])
    assert_equal(log['url'], expected_log['url'])
    assert_equal(log['user_agent'], expected_log['user_agent'])
    assert_equal(log['message'], expected_log['message'])
  end

  it 'does not log PII' do
    request.post("/user/info", input_data: {credit_card_no: '1234'})
    log = output.string
    assert_includes log, "POST: /user/info"
    refute_includes log, 'credit_card_no'
    refute_includes log, '1234'
  end

  it 'logs an error message when a request is bad' do
    -> { bad_request.get("/some/path") }.must_raise StandardError
    log = JSON.parse(output.string)
    assert_equal log['log']['level'], 'error'
    assert_equal log['error']['message'], 'some exception'
    assert_equal log['error']['type'], 'StandardError'
    assert_includes log['error']['stack_trace'], 'request_logger_test.rb'
  end
end

def request
  app = ->(env) { [200, env, "app"] }
  base_request(app)
end

def bad_request
  app = Rack::Lint.new ->(_env) { raise StandardError, 'some exception' }
  base_request(app)
end

def base_request(app)
  logger = Twiglet::Logger.new('example', output: output)
  req_logger = RequestLogger.new(app, logger)
  Rack::MockRequest.new(req_logger)
end
