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
    raise e
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

  # https://www.elastic.co/guide/en/ecs/1.5/ecs-field-reference.html
  def get_fields(env, status)
    message = "#{env['REQUEST_METHOD']}: #{env['PATH_INFO']}"

    {
      http: http_fields(env, status),
      url: url_fields(env),
      client: {
        ip: env['HTTP_TRUE_CLIENT_IP'] || env['REMOTE_ADDR']
      },
      user_agent: {
        original: env['HTTP_USER_AGENT']
      },
      message: message
    }
  end

  def http_fields(env, status)
    {
      request: {
        method: env['REQUEST_METHOD'],
        mime_type: env['HTTP_ACCEPT']
      },
      response: {
        status: status
      },
      version: env['HTTP_VERSION']
    }
  end

  def url_fields(env)
    {
      path: env['PATH_INFO'],
      query: env['QUERY_STRING'],
      domain: env['SERVER_NAME']
    }
  end
end
