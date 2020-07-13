require 'minitest/autorun'
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
    request.get("/some/path?some_var=1")
    log = JSON.parse(output.string)
    http_body = {
      "request" => {
        "https_enabled" => "off",
        "method" => "GET",
        "path" => "/some/path",
        "query" => "some_var=1",
        "server" => "example.org"
      },
      "response" => {
        "status" => 200,
        "body" => { "bytes" => "0" }
      }
    }
    assert_equal http_body, log["http"]
    assert_equal "GET: /some/path", log["message"]
  end

  it 'does not log PII' do
    request.post("/user/info", input_data: {credit_card_no: '1234'})
    log = output.string
    assert_includes log, "POST: /user/info"
    refute_includes log, 'credit_card_no'
    refute_includes log, '1234'
  end

  it 'logs an error message when a request is bad' do
    bad_request.get("/some/path")
    log = JSON.parse(output.string)
    assert_equal 'error', log['log']['level']
    assert_equal 'some exception', log['error']['message']
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
