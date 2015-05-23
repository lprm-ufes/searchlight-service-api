events = require './events'
utils = require './utils'
ajax = require './ajax'
   

class Config
  @debug = true
  @EVENT_READY = 'config:ready.slsapi'
  @EVENT_FAIL = 'config:fail.slsapi'

  constructor: (opcoes)->
    @id = utils.md5(JSON.stringify(opcoes)) + parseInt(1000*Math.random())

    self = @

    @parseOpcoes(opcoes)
    if opcoes.urlConfServico
      # merge with confservice if have urlConfService coletor
      xhr = ajax.get opcoes.urlConfServico
      xhr.done (res) ->
        self.parseOpcoes(res.body)
        events.trigger(self.id,Config.EVENT_READY)
      xhr.fail (err)->
        events.trigger(self.id,Config.EVENT_FAIL,{err:err,message:'Error: não foi possível carregar configuração da visualização'})
    else
        setTimeout((()->events.trigger(self.id,Config.EVENT_READY)),5)


  parseOpcoes: (opcoes,view)->
    @opcoes = new utils.Dicionario(opcoes)
    @serverURL = @opcoes.get 'serverURL', @serverURL or 'http://sl.wancharle.com.br'
    @createURL = @opcoes.get 'createURL', @createURL or "#{@serverURL}/note/create/"
    @loginURL = @opcoes.get 'loginURL', @loginURL or "#{@serverURL}/user/login/"
    @logoutURL = @opcoes.get 'logoutURL', @logoutURL or "#{@serverURL}/user/logout/"
    @notesURL = @opcoes.get 'notesURL', @notesURL or "#{@serverURL}/note/"
    @notebookURL = @opcoes.get 'notebookURL', @notebookURL or "#{@serverURL}/notebook/"
    @dataSources = @opcoes.get 'dataSources', @dataSources or []
    if not view
      @coletorNotebookId = @opcoes.get 'storageNotebook', ''


    @noteid = @opcoes.get 'noteid', @noteid or false

module.exports={'Config':Config }

# vim: set ts=2 sw=2 sts=2 expandtab:

