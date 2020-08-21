# Twiglet: Ruby version
Like a log, only smaller.

This library provides a minimal JSON logging interface suitable for use in (micro)services.  See the [RATIONALE](RATIONALE.md) for design rationale and an explantion of the Elastic Common Schema that we are using for log attribute naming.

## Installation

```bash
gem install twiglet
```

## How to use

Create a new logger like so:

```ruby
require 'twiglet/logger'
logger = Twiglet::Logger.new('service name')
```

A hash can optionally be passed in as a keyword argument for `default_properties`. This hash must be in the Elastic Common Schema format and will be present in every log message created by this Twiglet logger object.

You may also provide an optional `output` keyword argument which should be an object with a `puts` method - like `$stdout`.

In addition, you can provide another optional keyword argument called `now`, which should be a function returning a `Time` string in ISO8601 format.

Lastly, you may provide the optional keyword argument `level` to initialize the logger with a severity threshold. Alternatively, the threshold can be updated at runtime by calling the `level` instance method.

The defaults for both `output` and `now` should serve for most uses, though you may want to override them for testing as we have done [here](test/logger_test.rb).

To use, simply invoke like most other loggers:

```ruby
logger.error({ event: { action: 'startup' }, message: "Emergency! There's an Emergency going on" })
```

This will write to STDOUT a JSON string:

```json
{"service":{"name":"service name"},"@timestamp":"2020-05-14T10:54:59.164+01:00","log":{"level":"error"},"event":{"action":"startup"},"message":"Emergency! There's an Emergency going on"}
```

Obviously the timestamp will be different.

Alternatively, if you just want to log some error string:

```ruby
logger.error( "Emergency! There's an Emergency going on")
```

This will write to STDOUT a JSON string:

```json
{"service":{"name":"service name"},"@timestamp":"2020-05-14T10:54:59.164+01:00","log":{"level":"error"}, "message":"Emergency! There's an Emergency going on"}
```

A message is always required unless a block is provided. The message can be an object or a string.

An optional error can also be provided, in which case the error message and backtrace will be logged in the relevant ECS compliant fields:

```ruby
db_err = StandardError.new('Connection timed-out')
logger.error({ message: 'DB connection failed.' }, db_err)

# this is also valid
logger.error('DB connection failed.', db_err)
```

These will both result in the same JSON string written to STDOUT:

```json
{"ecs":{"version":"1.5.0"},"@timestamp":"2020-08-21T15:44:37.890Z","service":{"name":"service name"},"log":{"level":"error"},"message":"DB connection failed.","error":{"message":"Connection timed-out"}}
```

Add log event specific information simply as attributes in a hash:

```ruby
logger.info({
  event: { action: 'HTTP request' },
  message: 'GET /pets success',
  trace: { id: '1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb' },
  http: {
    request: { method: 'get' },
    response: { status_code: 200 }
  },
  url: { path: '/pets' }
})
```

This writes:

```json
{"service":{"name":"service name"},"@timestamp":"2020-05-14T10:56:49.527+01:00","log":{"level":"info"},"event":{"action":"HTTP request"},"message":"GET /pets success","trace":{"id":"1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb"},"http":{"request":{"method":"get"},"response":{"status_code":200}},"url":{"path":"/pets"}}
```

Similar to error you can use string logging here as:

```
logger.info('GET /pets success')
```

This writes:

```json
{"service":{"name":"service name"},"@timestamp":"2020-05-14T10:56:49.527+01:00","log":{"level":"info"}}
```

It may be that when making a series of logs that write information about a single event, you may want to avoid duplication by creating an event specific logger that includes the context:

```ruby
request_log = logger.with({ event: { action: 'HTTP request'}, trace: { id: '1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb' }})
```

This can be used like any other Logger instance:

```ruby
request_logger.error({
    message: 'Error 500 in /pets/buy',
    http: {
        request: { method: 'post', 'url.path': '/pet/buy' },
        response: { status_code: 500 }
    }
})
```

which will print:

```json
{"service":{"name":"service name"},"@timestamp":"2020-05-14T10:58:30.780+01:00","log":{"level":"error"},"event":{"action":"HTTP request"},"trace":{"id":"126bb6fa-28a2-470f-b013-eefbf9182b2d"},"message":"Error 500 in /pets/buy","http":{"request":{"method":"post","url.path":"/pet/buy"},"response":{"status_code":500}}}
```

## Use of dotted keys (DEPRECATED)

Writing nested json objects could be confusing. This library has a built-in feature to convert dotted keys into nested objects, so if you log like this:

```ruby
logger.info({
    'event.action': 'HTTP request',
    message: 'GET /pets success',
    'trace.id': '1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb',
    'http.request.method': 'get',
    'http.response.status_code': 200,
    'url.path': '/pets'
})
```

or mix between dotted keys and nested objects:

```ruby
logger.info({
    'event.action': 'HTTP request',
    message: 'GET /pets success',
    trace: { id: '1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb' },
    'http.request.method': 'get',
    'http.response.status_code': 200,
    url: { path: '/pets' }
})
```

Both cases would print out exact the same log item:

```json
{"service":{"name":"service name"},"@timestamp":"2020-05-14T10:59:31.183+01:00","log":{"level":"info"},"event":{"action":"HTTP request"},"message":"GET /pets success","trace":{"id":"1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb"},"http":{"request":{"method":"get"},"response":{"status_code":200}},"url":{"path":"/pets"}}
```

## How to contribute

First: Please read our project [Code of Conduct](../CODE_OF_CONDUCT.md).

Second: run the tests and make sure your changes don't break anything:

```bash
bundle exec rake test
```

Then please feel free to submit a PR.
