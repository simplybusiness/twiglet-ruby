# Middleware for logging request logs
class RequestLogger
  def initialize(app, logger)
    @app = app
    @logger = logger
  end

  def call(env)
    status, headers, body = @app.call(env)
    log(env, status)
    [status, headers, body]
  rescue StandardError => e
    log_error(env, 500, e)
    [500, {}, body]
  end

  private

  def log(env, status)
    fields = get_fields(env, status)
    @logger.info(fields)
  end

  def log_error(env, status, error)
    fields = get_fields(env, status)
    @logger.error(fields, error)
  end

  def get_fields(env, status)
    message = "#{env['REQUEST_METHOD']}: #{env['PATH_INFO']}"

    {
      http: {
        request: {
          method: env['REQUEST_METHOD'],
          server: env['SERVER_NAME'],
          https_enabled: env['HTTPS'],
          path: env['PATH_INFO'],
          query: env['QUERY_STRING']  # Don't log PII query params
        },
        response: {
          status: status,
          body: { bytes: env['CONTENT_LENGTH'] }
        }
      },
      message: message
    }
  end
end
