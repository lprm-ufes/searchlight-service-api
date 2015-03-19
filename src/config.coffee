utils = require './utils.coffee'
class Config
  constructor: (opcoes)->
    @opcoes = new utils.Dicionario(opcoes)

    @serverURL = @opcoes.get 'serverURL', 'http://sl.wancharle.com.br'
    @createURL = @opcoes.get 'createURL', "#{@serverURL}/note/create/"
    @loginURL = @opcoes.get 'loginURL', "#{@serverURL}/user/login/"
    @logoutURL = @opcoes.get 'logoutURL', "#{@serverURL}/user/logout/"
    @notesURL = @opcoes.get 'notesURL', "#{@serverURL}/note/"

module.exports={'Config':Config }

# vim: set ts=2 sw=2 sts=2 expandtab:

