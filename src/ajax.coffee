isRunningOnBrowser = require('./utils').isRunningOnBrowser
request = require('superagent')
if not isRunningOnBrowser
  request = request.agent() # para cookies

class Ajax

  constructor: (options)->
    @xhr = null
    @donecb = null
    @failcb = null
    @request = request
    @options = options

  get: (params)->
    @xhr = @request.get(params)
    if isRunningOnBrowser
      @xhr.withCredentials()

    # used to download files of octet-stream type like .csv
    if @options and @options.buffer
      @xhr.buffer()

    # set the content type of request
    if @options and @options.type
      @xhr.type(@options.type)
     
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
      
get = (params,options)->
  return new Ajax(options).get(params)
post = (params)->
  return new Ajax().post(params)
del = (params)->
  return new Ajax().delete(params)


module.exports = {
    get: get
    post: post
    del: del

    Ajax: Ajax
  }

# vim: set ts=2 sw=2 sts=2 expandtab:

