// Dependencies
const jasmine = require("jasmine")
const Logger = require("./logger")

// Constants
const DEBUG = false

// Helpers
class FakeConsole {
  constructor () {
    this.printed = ""
  }

  log (x) {
    this.printed = x
    if (DEBUG) { console.log(x) }
  }
}

// Tests
describe("logging", () => {
  beforeAll(() => {
    this.log = Logger({
      now: () => "2016-02-15T12:34:56.789Z",
      output: new FakeConsole(),
      service: "my-super-service"
    })
  })

  it("should log mandatory attributes", () => {
    this.log.error({})
    const contents = this.log.output.printed
    expect(contents.timestamp).toBe("2016-02-15T12:34:56.789Z")
    expect(contents.service.name).toBe("my-super-service")
    expect(contents.log.level).toBe("ERROR")
  })

  it("should log the provided message", () => {
    this.log.error({ event: { action: "exception" }, message: "Emergency! Emergency!" })
    const contents = this.log.output.printed

    expect(contents.event.action).toBe("exception")
    expect(contents.message).toBe("Emergency! Emergency!")
  })

  it("should log scoped properties defined at creation", () => {
    const extra_properties = {
      trace: {
        id: "1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb"
      },
      request: { method: "GET" },
      response: { status_code: 200 }
    }
    const my_logger = Logger({
      now: () => "2016-02-15T12:34:56.789Z",
      output: new FakeConsole(),
      service: "my-super-service"
    }, extra_properties)

    my_logger.error(extra_properties)
    const contents = my_logger.output.printed

    expect(contents.trace.id).toBe("1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb")
    expect(contents.request.method).toBe("GET")
    expect(contents.response.status_code).toBe(200)
  })
})
