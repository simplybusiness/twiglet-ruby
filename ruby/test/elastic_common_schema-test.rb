require "minitest/autorun"
require_relative "../elastic_common_schema"

describe ElasticCommonSchema do
  before do
    @ecs = Object.new
    @ecs.extend(ElasticCommonSchema)
  end

  it "should retain an object without . in any keys" do
    actual = {
      message: "Out of pets exception",
      service: {
        name: "petshop"
      },
      log: {
        level: "error"
      },
      "@timestamp": "2020-05-09T15:13:20.736Z"
    }

    expected = @ecs.to_nested(actual)
    assert_equal actual, expected
  end

  it "should convert keys with . into nested objects" do
    actual = {
      "service.name": "petshop",
      "log.level": "error"
    }

    nested = @ecs.to_nested(actual)

    assert_equal "petshop", nested[:service][:name]
    assert_equal "error", nested[:log][:level]
  end

  it "should group nested objects" do
    actual = {
      "service.name": "petshop",
      "service.id": "ps001",
      "service.version": "0.9.1",
      "log.level": "error"
    }

    nested = @ecs.to_nested(actual)
    
    assert_equal "petshop", nested[:service][:name]
    assert_equal "ps001", nested[:service][:id]
    assert_equal "0.9.1", nested[:service][:version]
    assert_equal "error", nested[:log][:level]
  end

  it "should cope with more than two levels" do
    actual = {
      "http.request.method": "get",
      "http.request.body.bytes": 112,
      "http.response.bytes": 1564,
      "http.response.status_code": 200
    }
    
    nested = @ecs.to_nested(actual)

    assert_equal "get", nested[:http][:request][:method]
    assert_equal 112, nested[:http][:request][:body][:bytes]
    assert_equal 1564, nested[:http][:response][:bytes]
    assert_equal 200, nested[:http][:response][:status_code]
  end

  it "#deep_merge() should work with two hashes without common keys" do
    first = { id: 1, name: "petshop" }
    second = { level: "debug", code: 5 }
    
    actual = @ecs.deep_merge(first, second)

    assert_equal 1, actual[:id]
    assert_equal "petshop", actual[:name]
    assert_equal "debug", actual[:level]
    assert_equal 5, actual[:code]
  end

  it "#deep_merge() should use the second value for shared keys" do
    first = { id: 1, name: "petshop", level: "debug" }
    second = { name: "petstore", level: "error", code: 5 }

    actual = @ecs.deep_merge(first, second)

    assert_equal 1, actual[:id]
    assert_equal "petstore", actual[:name]
    assert_equal "error", actual[:level]
    assert_equal 5, actual[:code]
  end

  it "#deep_merge() should merge two sub-keys" do
    first = { service: { name: "petshop" }  }
    second = { service: { id: "ps001" } }
    
    actual = @ecs.deep_merge(first, second)
    assert_equal "petshop", actual[:service][:name]
    assert_equal "ps001", actual[:service][:id]
  end

  it "#deep_merge() should merge sub-keys in more than 2 levels" do
    first = { http: { request: { method: "get",  bytes: 124 }}}
    second = { http: { response: { status_code: 200, bytes: 5001 }}}

    actual = @ecs.deep_merge(first, second)

    assert_equal "get", actual[:http][:request][:method]
    assert_equal 124, actual[:http][:request][:bytes]
    assert_equal 200, actual[:http][:response][:status_code]
    assert_equal 5001, actual[:http][:response][:bytes]
  end

  it "#deep_merge() should work when the first key is empty" do
    first = {}
    second = { id: 1 }
    
    actual = @ecs.deep_merge(first, second)

    assert_equal 1, actual[:id]
  end

  it "#deep_merge() should work when the second key is empty" do
    first = { id: 1 }
    second = {}
    
    actual = @ecs.deep_merge(first, second)

    assert_equal 1, actual[:id]
  end

end
