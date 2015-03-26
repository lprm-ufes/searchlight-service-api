
class Notebook
  @instances = {} 

  @getInstance: (config) ->
    return @instances[config.id]

  constructor: (config)->
    Notebook.instances[config.id] = @ 
    @config = config

  getByName: (notebookName,callback,callbackFail=null)->
    url = "#{@config.notebookURL}?name=#{notebookName}"
    $.get url,(data)->
      console.log('ola')
      callback(data)


  getById: (notebookId,callback,callbackFail=null)->
    url = "#{@config.notebookURL}?id=#{notebookId}"
    $.get url, callback, callbackFail

module.exports = {'Notebook': Notebook} 

# vim: set ts=2 sw=2 sts=2 expandtab:

