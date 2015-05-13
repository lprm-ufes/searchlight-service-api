ajax = require './ajax'

class Notebook
  @instances = {} 

  @getInstance: (config) ->
    return @instances[config.id]

  constructor: (config)->
    Notebook.instances[config.id] = @ 
    @config = config

  getByName: (notebookName,callback,callbackFail=null)->
    url = "#{@config.notebookURL}?name=#{notebookName}"
    xhr = ajax.get url
    xhr.done((res)->callback(res.body))
    xhr.fail((err)->callbackFail(err))


  getById: (notebookId,callback,callbackFail=null)->
    url = "#{@config.notebookURL}?id=#{notebookId}"
    xhr = ajax.get url
    xhr.done((res)->callback(res.body))
    xhr.fail((err)->callbackFail(err))

module.exports = {'Notebook': Notebook} 

# vim: set ts=2 sw=2 sts=2 expandtab:

