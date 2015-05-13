isRunningOnBrowser = require('./utils').isRunningOnBrowser
request = require('superagent')
if not isRunningOnBrowser
  request = request.agent() # para cookies

class Ajax

  constructor: ()->
    @xhr = null
    @parseJson = true
    @donecb = null
    @failcb = null
    @request = request

  get: (params)->
    @xhr = @request.get(params)
    if isRunningOnBrowser
      @xhr.withCredentials()
    @xhr.end((err,res)=>@end(err,res))
    return @

  post: (params)->
    if "data" of params
      @xhr = @request.post(params['url']).send( params['data'])
    else
      @xhr = @request.post(params)
    if isRunningOnBrowser
      @xhr.withCredentials()
    @xhr.end((err,res)=>@end(err,res))
    return @

  end: (err,res)->
    if err
      @failcb(err)
    else
      @donecb(res)

  delete: (params)->
    @xhr = @request.del params
    if isRunningOnBrowser
      @xhr.withCredentials()
    @xhr.end((err,res)=>@end(err,res))
    return @

  done: (cb)->
    @donecb = cb

  fail: (cb)->
    @failcb = cb
      
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
if isRunningOnBrowser
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

