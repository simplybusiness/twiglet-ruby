require 'twiglet/logger'
require 'request_logger'

# basic rack application
class Application
  def call(_env)
    status  = 200
    headers = { "Content-Type" => "text/json" }
    body    = ["Example rack app"]

    [status, headers, body]
  end
end

use RequestLogger, Twiglet::Logger.new('example_app')

run Application.new
