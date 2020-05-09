const jasmine = require("jasmine")
const json_helper = require("../json-helper")

describe("json_helper", () => {
  it("should retain an object without . in any keys", () => {
    const json = {
      message: "Out of pets exception",
      service: {
        name: "petshop"
      },
      log: {
        level: "ERROR"
      },
      timestamp: "2020-05-09T15:13:20.736Z"
    }

    const converted = json_helper(json)
    expect(json).toEqual(converted)
  })

  it("should convert keys with . into nested objects", () => {
    const json = {
      message: "Out of pets exception",
      "service.name": "petshop",
      "log.level": "ERROR",
      timestamp: "2020-05-09T15:13:20.736Z"
    }

    const converted = json_helper(json)

    expect(converted).toEqual({
      message: "Out of pets exception",
      service: {
        name: "petshop"
      },
      log: {
        level: "ERROR"
      },
      timestamp: "2020-05-09T15:13:20.736Z"
    })
  })

  it("should group nested objects", () => {
    const json = {
      message: "Out of pets exception",
      "service.name": "petshop",
      "service.id": "ps001",
      "service.version": "0.9.1",
      "log.level": "ERROR",
      timestamp: "2020-05-09T15:13:20.736Z"
    }

    const converted = json_helper(json)

    expect(converted).toEqual({
      message: "Out of pets exception",
      service: {
        id: "ps001",
        name: "petshop",
        "service.version": "0.9.1"
      },
      log: {
        level: "ERROR"
      },
      timestamp: "2020-05-09T15:13:20.736Z"
    })
  })

  it("should cope with more than two levels", () => {
    const json = {
      message: "Escaped pet situation",
      "service.name": "petshop",
      "log.level": "DEBUG",
      timestamp: "2020-05-09T15:13:20.736Z",
      "http.request.method": "GET",
      "http.request.body.bytes": 112,
      "http.response.bytes": 1564,
      "http.response.status_code": 200
    }

    const converted = json_helper(json)

    expect(converted).toEqual({
      message: "Escaped pet situation",
      service: {
        name: "petshop"
      },
      log: {
        level: "DEBUG"
      },
      timestamp: "2020-05-09T15:13:20.736Z",
      http: {
        request: {
          method: "GET",
          body: {
            bytes: 112
          }
        },
        response: {
          bytes: 1564,
          status_code: 200
        }
      }
    })
  })
})
