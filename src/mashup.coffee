ajax = require './ajax'

class Mashup
  constructor:(@config)->
    @config.register(@)

  parseOpcoes: (@opcoes)->
    @createURL= @opcoes.get 'mashupCreateURL', @createURL or "#{@config.serverURL}/mashup/create/"
    @readURL= @opcoes.get 'mashupReadURL', @readURL or "#{@config.serverURL}/mashup/"
    @updateURL= @opcoes.get 'mashupUpdateURL', @updateURL or "#{@config.serverURL}/mashup/update/"
    @cacheURL= @opcoes.get 'mashupCacheURL', @cacheURL or "#{@config.serverURL}/mashup/getCachedURL"

    @title = @opcoes.get 'title', @title or ''

    @id = @opcoes.get 'id', @id or ''
    if @id
      @useCache = true
    else
      @useCache = false

  toJSON:->
    {
      'mashupCreateURL':@createURL
      'mashupReadURL':@createURL
      'mashupUpdateURL':@createURL
      'title': @title
      'id': @id
    }

  save: (success, fail)->
    xhr = ajax.post {
      url: @createURL
      data:@config.toJSON()
    }
    xhr.done (res) ->
      self.parseOpcoes(res.body)
      events.trigger(self.id,Config.EVENT_READY)
    xhr.fail (err)->
      events.trigger(self.id,Config.EVENT_FAIL,{err:err,message:'Error: não foi possível carregar configuração da visualização'})



module.exports = {'Mashup':Mashup}

# vim: set ts=2 sw=2 sts=2 expandtab:

