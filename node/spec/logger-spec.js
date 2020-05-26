// Dependencies
const Logger = require("../logger")

// Constants
const DEBUG = process.env.DEBUG

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

  it("should throw an error without a message", () => {
    expect(() => {
      this.log.info()
    }).toThrow()
  })

  it("should log mandatory attributes", () => {
    this.log.error({ message: "Out of pets exception" })
    const contents = JSON.parse(this.log.output.printed)
    expect(contents["@timestamp"]).toBe("2016-02-15T12:34:56.789Z")
    expect(contents.service.name).toBe("petshop")
    expect(contents.log.level).toBe("error")
    expect(contents.message).toBe("Out of pets exception")
  })

  it("should log the provided message", () => {
    this.log.error({ event: { action: "exception" }, message: "Emergency! Emergency!" })
    const contents = JSON.parse(this.log.output.printed)

    expect(contents.event.action).toBe("exception")
    expect(contents.message).toBe("Emergency! Emergency!")
  })

  it("should log a stack trace if provided", () => {
    try {
      console.thing()
    } catch (err) {
      this.log.error({ message: "An error!" }, err)
    }
    const contents = JSON.parse(this.log.output.printed)

    expect(contents.message).toBe("An error!")
    expect(contents.error.message).toBe("console.thing is not a function")
    expect(contents.error.stacktrace[1]).toContain("logger-spec")
  })

  it("should log scoped properties defined at creation", () => {
    const extraProperties = {
      trace: {
        id: "1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb"
      },
      message: "GET /cats",
      request: { method: "get" },
      response: { status_code: 200 }
    }
    const myLogger = Logger({
      now: () => "2016-02-15T12:34:56.789Z",
      output: new FakeConsole(),
      service: "petshop"
    }, extraProperties)

    myLogger.error(extraProperties)
    const contents = JSON.parse(myLogger.output.printed)

    expect(contents.trace.id).toBe("1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb")
    expect(contents.request.method).toBe("get")
    expect(contents.response.status_code).toBe(200)
    expect(contents.message).toBe("GET /cats")
  })

  it("should be able to add properties with '.with'", () => {
    // Let's add some context to this customer journey
    const purchaseLog = this.log.with({
      trace: { id: "1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb" },
      customer: { full_name: "Freda Bloggs" },
      event: { action: "pet purchase" }
    })
    // do stuff
    purchaseLog.info({
      message: "customer bought a dog",
      pet: { name: "Barker", species: "dog", breed: "Bitsa" }
    })
    const contents = JSON.parse(purchaseLog.output.printed)

    expect(contents.trace.id).toBe("1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb")
    expect(contents.customer.full_name).toBe("Freda Bloggs")
    expect(contents.event.action).toBe("pet purchase")
    expect(contents.message).toBe("customer bought a dog")
    expect(contents.pet.name).toBe("Barker")
  })

  it("should be able to convert dotted keys to nested objects", () => {
    this.log.debug({
      "trace.id": "1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb",
      "customer.full_name": "Freda Bloggs",
      "event.action": "pet purchase",
      message: "customer bought a dog",
      "pet.name": "Barker",
      "pet.species": "dog",
      "pet.breed": "Bitsa"
    })
    const contents = JSON.parse(this.log.output.printed)

    expect(contents.trace.id).toBe("1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb")
    expect(contents.customer.full_name).toBe("Freda Bloggs")
    expect(contents.event.action).toBe("pet purchase")
    expect(contents.message).toBe("customer bought a dog")
    expect(contents.pet.name).toBe("Barker")
    expect(contents.pet.species).toBe("dog")
    expect(contents.pet.breed).toBe("Bitsa")
  })

  it("should be able to mix dotted keys and nested objects", () => {
    this.log.debug({
      "trace.id": "1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb",
      "customer.full_name": "Freda Bloggs",
      "event.action": "pet purchase",
      message: "customer bought a dog",
      pet: { name: "Barker", breed: "Bitsa" },
      "pet.species": "dog"
    })
    const contents = JSON.parse(this.log.output.printed)

    expect(contents.trace.id).toBe("1c8a5fb2-fecd-44d8-92a4-449eb2ce4dcb")
    expect(contents.customer.full_name).toBe("Freda Bloggs")
    expect(contents.event.action).toBe("pet purchase")
    expect(contents.message).toBe("customer bought a dog")
    expect(contents.pet.name).toBe("Barker")
    expect(contents.pet.species).toBe("dog")
    expect(contents.pet.breed).toBe("Bitsa")
  })

  describe("enforcing non-empty message", () => {
    it("should throw an error on an empty message", () => {
      expect(() => {
        this.log.info("")
      }).toThrow()
    })

    it("should throw an error on a message of blank spaces", () => {
      expect(() => {
        this.log.info("     ")
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

    it("should throw an error if message property is missing", () => {
      expect(() => {
        this.log.debug({ event: { action: "pet purchase" }})
      }).toThrow()
    })

    it("should throw an error on an undefined message as a property", () => {
      expect(() => {
        this.log.debug({ event: { action: "pet purchase" }, message: undefined })
      }).toThrow()
    })

    it("should throw an error on an null message as a property", () => {
      expect(() => {
        this.log.debug({ event: { action: "pet purchase" }, message: null })
      }).toThrow()
    })

    it("should throw an error on an empty message as a property", () => {
      expect(() => {
        this.log.debug({ event: { action: "pet purchase" }, message: "" })
      }).toThrow()
    })

    it("should throw an error on an message of blank spaces as a property", () => {
      expect(() => {
        this.log.debug({ event: { action: "pet purchase" }, message: "   " })
      }).toThrow()
    })
  })
})
