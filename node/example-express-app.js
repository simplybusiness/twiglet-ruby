// Imports
const Logger = require("./logger")
const express = require("express")

// Constants
const PORT = 8080

// Define a logger
const log = Logger({ service: "petshop" })

// Define some express middleware
const loggingMiddleware = (req, res, next) => {
  log.info({
    event: { action: "http request" },
    message: "request received",
    http: {
      url: {
        path: req.path,
        query: req.query,
        original: req.originalUrl
      },
      request: { method: req.method.toLowerCase() },
      response: { status_code: 200 }
    }
  })
  next()
}

const errorHandler = (err, req, res, next) => {
  if (res.headersSent) {
    return next(err)
  }
  // Probably no need for URL/request info here as request
  // already logged by previous middleware
  log.error({
    message: "Error",
    response: { status_code: 500 }}, err)
  res.status(500)
  res.render('An error has occurred')
}

// Our server
var app = express()

app.use(loggingMiddleware)

app.get("/", (req, res) => {
  res.send("This is the home Page")
})

app.get("/broken", (req, res) => {
  throw(new Error("Emergency!"))
})

app.use(errorHandler)

// Start our petshop
app.listen(PORT, () => {
  log.info({
    event: { action: "startup" },
    message: `Ready to go, listening on port ${PORT}`,
    server: { port: PORT }
  })
})
