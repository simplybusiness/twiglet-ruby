# Twig: Node.js version

This library provides a minimal JSON logging interface suitable for use in (micro)services. See the [README](../README.md) for design rationale and an explantion of the Elastic Common Schema that we are using for log attribute naming.

## Installation

    npm install --save @simplybusiness/twig

## How to use

Create a new logger like so:

    const Logger = require('./logger')
    const log = new Logger({ now: () => (new Date).toISOString(),
                             output: console,
                             service: "petshop" })

To use, simply invoke like most other loggers:

    log.error({ event: { action: "startup" }, message: "Emergency! There's an Emergency going on" })

This will write to STDOUT a JSON string:

    {"@timestamp":"2020-05-07T09:06:52.409Z","service":{"name":"petshop"},"event":{"action":"startup"},"log":{"level":"ERROR"},"message":"Emergency! There's an Emergency going on"}

Obviously the timestamp will be different.

Add log event specific information simply as attributes in a POJO (Plain Old Javascript Object):

    log.info({
      event: { action: "HTTP request" },
      message: "GET /pets success",
      trace: { id: "1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb" },
      http: {
        request: { method: "get" },
        response: { status_code: 200 }
      },
      url: { path: "/pets" }
    })

This writes:

    {"service":{"name":"petstore"},"@timestamp":"2020-05-07T09:06:52.409Z","event":{"action":"HTTP request"},"log":{"level":"INFO"},"trace":{"id":"1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb"},"http":{"request":{"method":"get","url.path":"/pets"},"response":{status_code:200}}}

It may be that when making a series of logs that write information about a single event, you may want to avoid duplication by creating an event specific logger that includes the context:

    const request_log = log.with({ event: { action: "HTTP request"}, trace: { id: "1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb" }})

This can be used like any other Logger instance:

    request_log.error({ message: "Error 500 in /pets/buy",
                        http: { request: { method: "POST", "url.path": "/pet/buy" },
                        response: { status_code: 500 }})

will print:

    {"service":{"name":"petstore"},"@timestamp":"2020-05-07T09:06:52.409Z","event":{"action":"HTTP request"},"log":{"level":"ERROR"},"trace":{"id":"1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb"},"http":{"request":{"method":"POST","url.path":"/pet/buy"},"response":{"status_code":500}},"message":"Error 500 in /pets/buy"}

# How to contribute

First: Please read our project [Code of Conduct](../CODE_OF_CONDUCT.md).

Second: run the tests and make sure your changes don't break anything:

    npm test

Then please feel free to submit a PR.
