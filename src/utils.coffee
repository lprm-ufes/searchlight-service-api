if typeof process.browser == 'undefined'
  md5 = require('blueimp-md5').md5
  extend = require('node.extend')
  CLIENT_SIDE = false
  dms2decPTBR = require('dms2dec-ptbr')
else
  CLIENT_SIDE = true
  md5 = window.md5 
  dms2decPTBR=window.dms2decPTBR

 
class Dicionario
  constructor: (js_hash)->
    if typeof js_hash == 'string'
      js_hash = JSON.parse(js_hash)
    @keys=Object.keys(js_hash)
    @data = js_hash

  get: (key,value) =>
    if key in @keys
      return @data[key]
    else
      return value

getURLParameter= (name) ->
  $(document).getUrlParam(name)


string2function = (func_code) ->
  #converte uma string para funcao          code = fonte.func_code
  re = /.*function *(\w*) *\( *([\w\,]*) *\) *\{/mg
  if ((m = re.exec(func_code)) != null)
    if (m.index == re.lastIndex)
      re.lastIndex++
    nome = m[1] or 'slsAnonymousFunction'
    if CLIENT_SIDE
      return eval("window['#{nome}']=#{func_code}")
    else
      # FIXME: memoria cresce pois funcoes ficam registradas no export (arranjar um jeito de associar apenas para aquele request)
      return eval("exports['#{nome}']=#{func_code}")
  else
    return null

# parseFloatPTBR :: String -> Float
#
# Converte uma string de um numero float no formato internacional e brasileiro num numero Float
# 
# Exemplos:
# > parseFloatPTBR(20.1)
# 20.1
# > parseFloatPTBR("20.1")
# 20.1
# > parseFloatPTBR("20,1")
# 20.1
# > parseFloatPTBR("-20.1")
# -20.1
# > parseFloatPTBR("-20,1")
# -20.1
parseFloatPTBR = (str) ->
  itens = String(str).match(/^(-*\d+)([\,\.]*)(\d+)?$/)
  if itens[2]
    return parseFloat(itens[1]+"."+itens[3])
  else
    return parseFloat(itens[1])

merge = (deep,target,source)->
  if CLIENT_SIDE
    if deep
      return $.extend(true,target,source)
    else
      return $.extend(target,source)
  else
    return extend(deep,target,source)


# exportando funções para acesso externo
if CLIENT_SIDE
  window.parseFloatPTBR = parseFloatPTBR
  window.string2function = string2function
  window.getURLParameter = getURLParameter



module.exports = {
    
    Dicionario: Dicionario
    parseFloatPTBR: parseFloatPTBR
    string2function: string2function
    getURLParameter: getURLParameter
    md5: md5
    dms2decPTBR: dms2decPTBR
    isRunningOnBrowser: CLIENT_SIDE
    merge: merge
  }
# vim: set ts=2 sw=2 sts=2 expandtab:

