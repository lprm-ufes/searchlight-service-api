utils = require './utils.coffee'

class Config
  constructor: (opcoes)->
    @id = md5(JSON.stringify(opcoes))

    self = @

    @parseOpcoes(opcoes)
    if opcoes.urlConfServico
      xhr = $.get opcoes.urlConfServico
      xhr.done (opcoes) ->
        self.parseOpcoes(opcoes)
        $(document).trigger('slsapi.config:sucesso')
      xhr.fail ()->
        $(document).trigger('slsapi.config:fail')
        alert('Error: não foi possível carregar configuração da visualização')

  parseOpcoes: (opcoes)->
    @opcoes = new utils.Dicionario(opcoes)
    @serverURL = @opcoes.get 'serverURL', 'http://sl.wancharle.com.br'
    @createURL = @opcoes.get 'createURL', "#{@serverURL}/note/create/"
    @loginURL = @opcoes.get 'loginURL', "#{@serverURL}/user/login/"
    @logoutURL = @opcoes.get 'logoutURL', "#{@serverURL}/user/logout/"
    @notesURL = @opcoes.get 'notesURL', "#{@serverURL}/note/"
    @notebookURL = @opcoes.get 'notebookURL', "#{@serverURL}/notebook/"
    @coletorNotebookId = @opcoes.get 'id', ''

  



module.exports={'Config':Config }

# vim: set ts=2 sw=2 sts=2 expandtab:

