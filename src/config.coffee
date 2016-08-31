events = require './events'
utils = require './utils'
ajax = require './ajax'
   

class Config
  @debug = true
  @EVENT_READY = 'config:ready.slsapi'
  @EVENT_FAIL = 'config:fail.slsapi'

  constructor: (opcoes)->
    @id = utils.md5(JSON.stringify(opcoes)) + parseInt(1000*Math.random())

    @children = []
    self = @

    @parseOpcoes(opcoes)
    if opcoes.urlConfServico
      # merge with confservice if have urlConfService coletor
      xhr = ajax.get opcoes.urlConfServico
      xhr.done (res) ->
        self.parseOpcoes(res.body)
        events.trigger(self.id,Config.EVENT_READY)
      xhr.fail (err)->
        events.trigger(self.id,Config.EVENT_FAIL,{err:err,message:'Não foi possível carregar configuração do serviço.'})
    else
        setTimeout((()->events.trigger(self.id,Config.EVENT_READY)),5)


  parseOpcoes: (opcoes,view)->
    @opcoesOriginais = opcoes
    @opcoes = new utils.Dicionario(opcoes)
    @serverURL = @opcoes.get 'serverURL', @serverURL or 'http://sl.wancharle.com.br'
    
    # do parseOpcoes in children
    for child in @children
      child.parseOpcoes(@opcoes)

  register: ( configInstance)->
    if configInstance.parseOpcoes
      configInstance.parseOpcoes(@opcoes)
    @children.push(configInstance)

  unregister: (instance)->
    i = @children.indexOf(instance)
    @children.splice(i,1)

  toJSON: ->
    json = {
      'storageNotebook':@coletorNotebookId
      'serverURL':@serverURL
    }

    for child in @children
        json = utils.merge(json,child.toJSON())

    return JSON.parse(JSON.stringify(json))


module.exports={'Config':Config }

# vim: set ts=2 sw=2 sts=2 expandtab:

