ajax = require './ajax'

class Notebook
  @instances = {} 

  @getInstance: (config) ->
    return @instances[config.id]

  parseOpcoes: (@opcoes)->
    @createURL = @opcoes.get 'notebookCreateURL', @createURL or "#{@config.serverURL}/notebook/create/"
    @readURL = @opcoes.get 'notebookReadURL', @readURL or "#{@config.serverURL}/notebook/"
    @updateURL = @opcoes.get 'notebookUpdateURL', @updateURL or "#{@config.serverURL}/notebook/update/"

  toJSON: ->
    {
      notebookCreateURL:@createURL
      notebookReadURL: @readURL
    }

  constructor: (config)->
    Notebook.instances[config.id] = @ 
    @config = config
    @config.register(@)

  
  get: (callback,callbackFail=null)->
    url = "#{@readURL}"
    xhr = ajax.get url
    xhr.done((res)->callback(res.body))
    xhr.fail((err)->callbackFail(err))

  getByName: (notebookName,callback,callbackFail=null)->
    url = "#{@readURL}?name=#{notebookName}"
    xhr = ajax.get url
    xhr.done((res)->callback(res.body))
    xhr.fail((err)->callbackFail(err))


  getById: (notebookId,callback,callbackFail=null)->
    url = "#{@readURL}?id=#{notebookId}"
    xhr = ajax.get url
    xhr.done((res)->callback(res.body))
    xhr.fail((err)->callbackFail(err))

  create: (nbname,success,fail)->
    xhr = ajax.post {
      url: @createURL
      data:
        name:nbname
    }
    xhr.done((res)->
     if res.body.id
        success(res.body)
      else
        fail('notebook not created'))
    xhr.fail(fail)

  update: (id,json,success,fail)->
    xhr = ajax.post {
      url: "#{@updateURL}#{id}/"
      data:json
    }
    xhr.done((res)->
     if res.body.id
        success(res.body)
      else
        fail('notebook not updated'))
 
    xhr.fail(fail)

  delete: (id,success,fail)->
    xhr = ajax.del "#{@readURL}#{id}/"
    xhr.done((res)->
     if res.body.id
        success(res.body)
      else
        fail('notebook not deleted'))
 
    xhr.fail(fail)




module.exports = {'Notebook': Notebook} 

# vim: set ts=2 sw=2 sts=2 expandtab:

