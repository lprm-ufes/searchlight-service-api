if typeof process.browser == 'undefined' 
  requestPromise = require('request-promise')
  errors = require('request-promise/errors')
  requestPromise.defaults({jar: true})
  CLIENT_SIDE = false
else
  CLIENT_SIDE = true
  

class Ajax

  constructor: ()->
    @xhr = null
    @parseJson = true
    if CLIENT_SIDE
      $.ajaxSetup({
        crossDomain: true,
        xhrFields: {
          withCredentials: true
        },
      })

  get: (params)->
    if CLIENT_SIDE
      @xhr = $.get params
    else
      @xhr = requestPromise.get params
    return @

  post: (params)->
    if CLIENT_SIDE
      if "data" of params
        @xhr = $.post params['url'], params['data']
      else
        @xhr = $.post params
    else
      if "data" of params
        @xhr = requestPromise.post {url:params['url'], formData:params['data']}
      else
        @xhr = requestPromise.post params
    return @

  delete: (params)->
    if CLIENT_SIDE
      params.type = "DELETE"
      params.crossDomains = true
      @xhr = $.ajax params
    else
      @xhr = requestPromise.del params
    return @

  done: (cb)->
    self = @
    if CLIENT_SIDE
      @xhr.done(cb)
    else
      cb2 = (data) -> 
        if self.parseJson
            data = JSON.parse(data)
        cb(data)
      @xhr.then(cb2,()->) # XXX: passando funcao anonima para evitar levantamento de exceções no .catch devido as promessas

  fail: (cb)->
    if CLIENT_SIDE
      cb2 = (jq)->
        body = jq.responseJSON or jq.responseText
        statusCode = jq.status
        reason = {
          response:
            body: body
            statusCode :statusCode
        }
        cb(reason)
      @xhr.fail(cb2)
    else
      @xhr.catch(cb)
      
get = (params)->
  return new Ajax().get(params)
post = (params)->
  return new Ajax().post(params)
del = (params)->
  return new Ajax().delete(params)





getJSONP = (url,func)->
  xhr = get({ 'url': url,'type':"POST", 'dataType': 'jsonp'})
  xhr.done(func)
  xhr.fail((e,ee)-> 
      if ee == "error"
        console.log('Erro ao baixar dados JSONP da fonte de dados\n'+url)
  )


getJSON = (url,func)->
  xhr = get({ 'url': url,
  'dataType': "json",'contentType': 'application/json','mimeType': "textPlain"})
  xhr.done(func)
  xhr.fail(()-> console.log('Erro ao baixar dados JSONP da fonte de dados\n'+url))


# exportando funções para acesso externo
if CLIENT_SIDE
  window.getJSONP = getJSONP
  window.getJSON = getJSON

module.exports = {
    get: get
    post: post
    del: del
    getJSON: getJSON
    getJSONP: getJSONP

    Ajax: Ajax
  }

# vim: set ts=2 sw=2 sts=2 expandtab:

