class Logger
  def initialize(service:, now:, output:, scoped_properties: {})
    @service = service
    @now = now
    @output = output
    @scoped_properties = scoped_properties
  end

  def debug(message)
    log(level: "debug", message: message)
  end

  def info(message)
    log(level: "info", message: message)
  end

  def warning(message)
    log(level: "warning", message: message)
  end

  def error(message)
    log(level: "error", message: message)
  end

  def critical(message)
    log(level: "critical", message: message)
  end

  def with(scoped_properties)
    Logger.new(service: @service,
               now: @now,
               output: @output,
               scoped_properties: scoped_properties)
  end

  private

  def log(level:, message:)
    message = case message
              when Hash
                message
              else
                { message: message.to_s }
              end
    total_message = message.merge({
                                   service: { name: @service },
                                   "@timestamp": @now.iso8601(3)
                                 })
    @output.puts total_message.to_json
  end
end


# https://stackoverflow.com/questions/9381553/ruby-merge-nested-hash#30225093
class ::Hash
  def deep_merge(second)
    merger = proc { |_, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
    merge(second.to_h, &merger)
  end
end

require 'date'
require 'json'
log = Logger.new(service: "Petshop", now: DateTime.now, output: $stdout)
log.debug(message: "some debug info")

log_request = log.with({ "http.request.method": "GET", "http.response.status_code": 500})
log_request.error({ message: "Out of pets exception" })
