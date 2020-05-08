// Dependencies
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
      service: "petshop"
    })
  })

  it("should log mandatory attributes", () => {
    this.log.error({ message: "" })
    const contents = this.log.output.printed
    expect(contents.timestamp).toBe("2016-02-15T12:34:56.789Z")
    expect(contents.service.name).toBe("petshop")
    expect(contents.log.level).toBe("ERROR")
    expect(contents.message).toBe("")
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
      message: "",
      request: { method: "GET" },
      response: { status_code: 200 }
    }
    const my_logger = Logger({
      now: () => "2016-02-15T12:34:56.789Z",
      output: new FakeConsole(),
      service: "petshop"
    }, extra_properties)

    my_logger.error(extra_properties)
    const contents = my_logger.output.printed

    expect(contents.trace.id).toBe("1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb")
    expect(contents.request.method).toBe("GET")
    expect(contents.response.status_code).toBe(200)
  })

  it("should be able to add properties with '.with'", () => {
    // Let's add some context to this customer journey
    const purchase_log = this.log.with({
      trace: { id: "1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb" },
      customer: { full_name: "Freda Bloggs" },
      event: { action: "pet purchase" }
    })
    // do stuff
    purchase_log.info({
      message: "customer bought a dog",
      pet: { name: "Barker", species: "dog", breed: "Bitsa" }
    })
    const contents = purchase_log.output.printed

    expect(contents.trace.id).toBe("1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb")
    expect(contents.customer.full_name).toBe("Freda Bloggs")
    expect(contents.event.action).toBe("pet purchase")
    expect(contents.message).toBe("customer bought a dog")
    expect(contents.pet.name).toBe("Barker")
  })

  describe("enforcing non-empty message", () => {
    it("should throw an error without a message", () => {
      expect(() => {
        this.log.info()
      }).toThrow()
    })

    it("should throw an error on an empty message", () => {
      expect(() => {
        this.log.info("")
      }).toThrow()
    })

    it("should throw an error on a null message", () => {
      expect(() => {
        this.log.info(null)
      }).toThrow()
    })

    it("should throw an error on an undefined message", () => {
      expect(() => {
        this.log.info(undefined)
      }).toThrow()
    })
  })
})
