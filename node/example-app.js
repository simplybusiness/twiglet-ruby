const Logger = require('./logger')

const PORT = 8080

const log = Logger({
  now: Date.now,
  output: console,
  service: "petshop"
})

// Start our petshop
log.info({
  event: {
    action: "startup"
  },
  message: `Ready to go, listening on port ${PORT}`,
  server: {
    port: PORT
  }
})

// We get a request
const requestLog = log.with({ event: { action: "HTTP request" }, trace: { id: "126bb6fa-28a2-470f-b013-eefbf9182b2d" }})

// Oh noes!
dbErr = true // this time!
if (dbErr) {
  requestLog.error({ message: "DB connection failed." })
}

// We return an error to the requester
requestLog.info({ message: "Internal Server Error", http: { request: { method: 'get'}, response: { status_code: 500 }}})

// Logging with a non-empty message is an anti-pattern and is therefore forbidden
// Both of the following lines would throw an error
// request_log.error()
// log.debug()
