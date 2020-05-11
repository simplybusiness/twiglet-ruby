const merge = require('deepmerge')

const json_helper = (json) => {
  return Object.keys(json).reduce((acc, cur) => {
    return merge(acc, build_nested_object(cur, json[cur]))
  }, {})
}

const build_nested_object = (key, val) => {
  return key.split(".").reverse().reduce((acc, cur) => {
    return {
      [cur]: acc
    }
  }, val)
}

module.exports = json_helper