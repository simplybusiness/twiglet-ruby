# frozen_string_literal: true

require_relative 'lib/twiglet/logger'

PORT = 8080

logger = Twiglet::Logger.new('petshop')

# Start our petshop
logger.info(
  {
    event: {
      action: 'startup'
    },
    message: "Ready to go, listening on port #{PORT}",
    server: {
      port: PORT
    }
  }
)

# Use text logging
logger.info("Ready to go, listening on port #{PORT}")
#
# We get a request
request_logger = logger.with(
  {
    event: {
      action: 'HTTP request'
    },
    trace: {
      id: '126bb6fa-28a2-470f-b013-eefbf9182b2d'
    }
  }
)

# Oh noes!
db_err = StandardError.new('Connection timed-out')

request_logger.error({ message: 'DB connection failed.' }, db_err) if db_err

# We return an error to the requester
request_logger.info(
  {
    message: 'Internal Server Error',
    http: {
      request: {
        method: 'get'
      },
      response: {
        status_code: 500
      }
    }
  }
)

# Logging with an empty message is an anti-pattern and is therefore forbidden
# Both of the following lines would throw an error
# request_logger.error({ message: "" })
# logger.debug({ message: " " })
