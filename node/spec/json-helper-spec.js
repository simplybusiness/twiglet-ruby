const jasmine = require("jasmine")
const json_helper = require("../json-helper")

describe("json_helper", () => {
  it("should retain an object without . in any keys", () => {
    const before = {
      message: "Out of pets exception",
      service: {
        name: "petshop"
      },
      log: {
        level: "error"
      },
      "@timestamp": "2020-05-09T15:13:20.736Z"
    }

    const after = json_helper(before)
    expect(before).toEqual(after)
  })

  it("should convert keys with . into nested objects", () => {
    const before = {
      message: "Out of pets exception",
      "service.name": "petshop",
      "log.level": "error",
      "@timestamp": "2020-05-09T15:13:20.736Z"
    }

    const after = {
      message: "Out of pets exception",
      service: {
        name: "petshop"
      },
      log: {
        level: "error"
      },
      "@timestamp": "2020-05-09T15:13:20.736Z"
    }

    expect(json_helper(before)).toEqual(after)
  })

  it("should group nested objects", () => {
    const before = {
      message: "Out of pets exception",
      "service.name": "petshop",
      "service.id": "ps001",
      "service.version": "0.9.1",
      "log.level": "error",
      "@timestamp": "2020-05-09T15:13:20.736Z"
    }

    const after = {
      message: "Out of pets exception",
      service: {
        id: "ps001",
        name: "petshop",
        version: "0.9.1"
      },
      log: {
        level: "error"
      },
      "@timestamp": "2020-05-09T15:13:20.736Z"
    }

    expect(json_helper(before)).toEqual(after)
  })

  it("should cope with more than two levels", () => {
    const before = {
      message: "Escaped pet situation",
      "service.name": "petshop",
      "log.level": "debug",
      "@timestamp": "2020-05-09T15:13:20.736Z",
      "http.request.method": "get",
      "http.request.body.bytes": 112,
      "http.response.bytes": 1564,
      "http.response.status_code": 200
    }

    const after = {
      message: "Escaped pet situation",
      service: {
        name: "petshop"
      },
      log: {
        level: "debug"
      },
      "@timestamp": "2020-05-09T15:13:20.736Z",
      http: {
        request: {
          method: "get",
          body: {
            bytes: 112
          }
        },
        response: {
          bytes: 1564,
          status_code: 200
        }
      }
    }

    expect(json_helper(before)).toEqual(after)
  })
})
