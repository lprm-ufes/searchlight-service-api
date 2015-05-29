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
      'mashupReadURL':@readURL
      'mashupUpdateURL':@updateURL
      'title': @title
      'id': @id
    }

  get:(title,user,success,fail)->
    xhr = ajax.get "#{@readURL}?user=#{user}&title=#{title}"
    xhr.done((res)->
      if res.body.length == 1 and res.body[0].id
        success(res.body[0])
      else
        fail('mashup not found'))
    xhr.fail(fail)

  create: (json,success,fail)->
    xhr = ajax.post {
      url: @createURL
      data:json
    }
    xhr.done((res)->
     if res.body.id
        success(res.body)
      else
        fail('mashup not created'))
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
        fail('mashup not updated'))
 
    xhr.fail(fail)


  delete: (id,success,fail)->
    xhr = ajax.del "#{@readURL}#{id}/"
    xhr.done(success)
    xhr.fail(fail)

  save: (success, fail)->
    json = @config.toJSON()
    if json.title and json.user
      @get(json.title,json.user,
        (found)=>
            @update(found.id,json,success,fail)
        ,(err)=>
          if typeof err == 'string' and err=='mashup not found'
            @create(json,success,fail)
          else
            fail(err)
          )
    else
      fail("you need a title and logged user to save a mashup")


module.exports = {'Mashup':Mashup}

# vim: set ts=2 sw=2 sts=2 expandtab:

