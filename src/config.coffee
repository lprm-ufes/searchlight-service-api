utils = require './utils.coffee'

class Config
  constructor: (opcoes)->
    @id = md5(JSON.stringify(opcoes))

    @opcoes = new utils.Dicionario(opcoes)

    @serverURL = @opcoes.get 'serverURL', 'http://sl.wancharle.com.br'
    @createURL = @opcoes.get 'createURL', "#{@serverURL}/note/create/"
    @loginURL = @opcoes.get 'loginURL', "#{@serverURL}/user/login/"
    @logoutURL = @opcoes.get 'logoutURL', "#{@serverURL}/user/logout/"
    @notesURL = @opcoes.get 'notesURL', "#{@serverURL}/note/"
    @notebookURL = @opcoes.get 'notebookURL', "#{@serverURL}/notebook/"
    @coletorNotebookId = @opcoes.get 'coletorNotebookId', ''


module.exports={'Config':Config }

# vim: set ts=2 sw=2 sts=2 expandtab:

