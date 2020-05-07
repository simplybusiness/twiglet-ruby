# Twig

Why Twig? Because it's a log, only micro-sized.

This is a machine-readable first, human-readable second, JSON-based logging micro-library suitable for a wide variety of microservice uses.

This logging library is available in a cornucopia of languages:
* [Ruby](ruby)
  - TBC
* [Python](python)
  - TBC
* [Node.js](node)
  - For more details see the Node-specific [README](node/README.md)

## Design considerations

The design goals of this library are:

- Write logs as JSON
- One line per log entry
- One JSON object per log entry
- Each log entry contains a severity[1]
- Each log entry contains an ISO8601 UTC timestamp
- Each log entry contains the name of the service that wrote it
- Each log entry pertains to an 'event'[2]
- Each log entry either a) propagates an existing trace.id or b) creates a new trace.id as a correlation ID if one does not already exist[3]
- Stack traces are written inside a single JSON log object rather than sprawling over several lines (TODO:)
- Personally Identifiable Information. Don't log it. 

[1] It turns out that there isn't a single authoritative standard for severity levels, we chose to go with DEBUG, INFO, WARNING, ERROR and CRITICAL as our choices.
[2] The ‘event’ here merely refers to the action that the customer (or employee, service, or other actor) is currently attempting. It does not refer specifically to Kafka, or CQRS, though that might be the case.
[3] A correlation ID is a UUIDv4 string

## Elastic Common Schema (ECS)
https://www.elastic.co/blog/introducing-the-elastic-common-schema
We have decided to standardise on the Elastic Common Schema for log attribute names. Whilst some attributes are expected for all logs, service owners should feel free to add relevant entries from the ECS schema if they are needed.
All application specific information is embedded in the `message` attribute JSON payload.

----------------------------------------------------------------- 
| Attribute name (mandatory) | Description                      |
-----------------------------------------------------------------
| log.level                  | String, is one of DEBUG, INFO,   |
|                            | WARNING, ERROR and CRITICAL.     |
-----------------------------------------------------------------
| service.name               | String, the name of the service  |
-----------------------------------------------------------------
| timestamp                  | String, ISO8601 UTC with         |
|                            | millisecond timestamp            |
-----------------------------------------------------------------
| message                    | JSON, the original log message   |
-----------------------------------------------------------------

-----------------------------------------------------------------
| Attribute name (optional)  | Description                      |
-----------------------------------------------------------------
| error.stack_trace          | JSON, the stack trace if         |
|                            | applicable, formatted as JSON[4] |
-----------------------------------------------------------------
| tags                       | Array, e.g. ["production"]       |
-----------------------------------------------------------------
| trace.id                   | String, UUIDv4 - this is a       |
|                            | correlation ID                   |
-----------------------------------------------------------------
| (other examples)           | ...                              |
-----------------------------------------------------------------



[4] Helper method to be provided to allow stack trace objects to be represented cleanly as JSON.

Errors should provide appropriate data using the fields from https://www.elastic.co/guide/en/ecs/current/ecs-error.html
If any other fields are provided in a log then these should be from the ECS schema rather than in a custom format, if at all possible.

## Example log output
```json
{
  "log.level": "INFO",
  "service.name": "payments",
  "timestamp": "2016-07-13T11:34:18.000Z",
  "event.action": "customer-payment-accepted",
  "trace.id": "bf6f5ea3-614b-42f5-8e73-43deea2d1838",
  "tags": ["staging"],
  "message": {
    "user.email": "sleepyfox@gmail.com",
    "pet.type": "cat",
    "pet.name": "Spot",
    "pet.colour": "Ginger Tabby"
  }
}
```

# LICENSE

This work is licensed under the MIT license - see the [LICENSE](LICENSE) file for further details.
