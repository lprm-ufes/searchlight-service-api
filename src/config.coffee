events = require './events'
utils = require './utils'
ajax = require './ajax'
   

class Config
  @debug = true
  @EVENT_READY = 'config:ready.slsapi'
  @EVENT_FAIL = 'config:fail.slsapi'

  constructor: (opcoes)->
    @id = utils.md5(JSON.stringify(opcoes))

    self = @

    @parseOpcoes(opcoes)
    if opcoes.urlConfServico
      xhr = ajax.get opcoes.urlConfServico
      xhr.done (opcoes) ->
        self.parseOpcoes(opcoes)
        events.trigger(self.id,Config.EVENT_READY)
      xhr.fail ()->
        console.log('Error: não foi possível carregar configuração da visualização')
        events.trigger(self.id,Config.EVENT_FAIL,'Error: não foi possível carregar configuração da visualização')


  parseOpcoes: (opcoes,view)->
    @opcoes = new utils.Dicionario(opcoes)
    @serverURL = @opcoes.get 'serverURL', 'http://sl.wancharle.com.br'
    @createURL = @opcoes.get 'createURL', "#{@serverURL}/note/create/"
    @loginURL = @opcoes.get 'loginURL', "#{@serverURL}/user/login/"
    @logoutURL = @opcoes.get 'logoutURL', "#{@serverURL}/user/logout/"
    @notesURL = @opcoes.get 'notesURL', "#{@serverURL}/note/"
    @notebookURL = @opcoes.get 'notebookURL', "#{@serverURL}/notebook/"
    @dataSources = @opcoes.get 'dataSources', []
    if not view
      @coletorNotebookId = @opcoes.get 'id', ''


module.exports={'Config':Config }

# vim: set ts=2 sw=2 sts=2 expandtab:

