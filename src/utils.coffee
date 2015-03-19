class Dicionario
  constructor: (js_hash)->
    @keys=Object.keys(js_hash)
    @data = js_hash

  get: (key,value) =>
    if key in @keys
      return @data[key]
    else
      return value

module.exports = {Dicionario:Dicionario}
# vim: set ts=2 sw=2 sts=2 expandtab:

