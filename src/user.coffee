notes = require './notes.coffee'
class User

  constructor: (@config)->
    @storage = window.localStorage
    @usuario = this.getUsuario()
    @notes = new notes.Notes(@config)

  isLogged: ()->
    return @getUsuario()

  getUsuario: () ->
    @usuario = @storage.getItem('Usuario')
    @user_id = @storage.getItem('user_id')
    return @usuario
  
  setUsuario: (usuario,json)->
    @user_id = json.id
    @usuario =  usuario
    @storage.setItem('Usuario',@usuario)
    @storage.setItem('user_id',@user_id)

  logout: (callback) ->
    @storage.removeItem('Usuario')
    @usuario = null
    @user_id = null
    $.get(@config.logoutURL,callback)

  login: (u,p) =>
    #disable the button so we can't resubmit while we wait
    if (u and  p)
      url = @config.loginURL
      $(document).trigger('slsapi.user:loginStart')
      $.post(url, {username:u,password:p}, (json) =>
        if json.error
          alert(json.error)
        else
          @setUsuario u, json
          #dispara mensagem de login com sucesso
          $(document).trigger('slsapi.user:loginSuccess')

        $(document).trigger('slsapi.user:loginFinish')
      ,"json").fail(() ->
        $(document).trigger('slsapi.user:loginFail')
        )
    return false

  getNotes: (callback)->
    @notes.getByUser(@user_id,(data) -> callback(data))
  
    
module.exports = {'User':User}
# vim: set ts=2 sw=2 sts=2 expandtab:

