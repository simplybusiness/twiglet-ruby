// A logger is an object that:
// Has scoped properties that are sent on every log message,
// Is configured with:
//   a 'now' function that returns a ISO datetime stamp string
//   a 'service' name
//   an 'output' function, that is typically console.log
// and exposes the following methods:
//   .debug
//   .info
//   .warning
//   .error
//   .critical
//   Each of which takes a single object and then logs to STDOUT
//   a JSON representation of the object on a single line.
// It also exposes a .with method that is a fluent interface that
// takes more properties and returns another logger that incorporates
// those properties.

const assert = require("assert")
const json_helper = require("./json-helper")

const Logger = (conf, scoped_properties) => {
  assert.equal(typeof(conf.now), "function",
               "configuration must have a now function")
  assert.equal(typeof(conf.service), "string",
               "configuration must have a service name")
  assert.equal(typeof(conf.output), "object",
               "configuration must have an output object")
  assert.equal(typeof(conf.output.log), "function",
               "configuration output.log must be a function")

  const { now, output, service } = conf
  
  const is_valid_string = (message) => {
    return message.trim().length > 0 
  }

  const log = (severity, message) => {
    if (typeof(message) === "string") {
      assert(is_valid_string(message),
             "There must be a non-empty message")
      message = { message: message }
    } else if (typeof(message) === "object") {
      assert(message.hasOwnProperty("message"),
             "Log object must have a 'message' property")
      assert(is_valid_string(message.message),
             "The 'message' property of log object must not be empty")
    } else {
      throw new Error("Message must be either an object or a string")
    }
    const total_message = { ...{ log: { level: severity },
                                 "timestamp": now(),
                                 service: { name: service }},
                            ...scoped_properties,
                            ...message }
    const nested_message = json_helper(total_message)
    output.log(nested_message)
  }

  return {
    now: now,
    output: output,
    service: service,
    scoped_properties: scoped_properties,
    debug: log.bind(null, 'DEBUG'),
    info: log.bind(null, 'INFO'),
    warning: log.bind(null, 'WARNING'),
    error: log.bind(null, 'ERROR'),
    critical: log.bind(null, 'CRITICAL'),
    with: (more_properties) => {
      return Logger(conf,
                    {...scoped_properties,
                     ...more_properties})
    } // end .with
  } // end return
} // end Logger

module.exports = Logger
