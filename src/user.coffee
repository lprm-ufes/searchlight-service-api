if typeof process.browser == 'undefined' 
  md5 = require('blueimp-md5').md5
  LocalStorage = require('node-localstorage').LocalStorage
  localStorage = new LocalStorage('./scratch')
  CLIENT_SIDE = false
else
  CLIENT_SIDE = true
  localStorage = window.localStorage
  md5 = window.md5 

events = require './events'
ajax = require './ajax'

class User
  @EVENT_LOGIN_SUCCESS = 'userLoginSuccess.slsapi'
  @EVENT_LOGIN_START = 'userLoginStart.slsapi'
  @EVENT_LOGIN_FINISH = 'userLoginFinish.slsapi'
  @EVENT_LOGIN_FAIL = 'userLoginFail.slsapi'

  @instances = {} 

  @getInstance: (config) ->
    return @instances[config.id]

  constructor: (@config)->
    User.instances[@config.id] = @
    @storage = localStorage
    @usuario = this.getUsuario()

  isLogged: ()->
    usuario = @getUsuario()
    
    if usuario
      tempo_logado = ((new Date()).getTime() - @logginTime)/1000
      if tempo_logado > 24*3600 # sessao expirou
        return false
      return true
    else
      return false



  getUsuario: () ->
    @usuario = @storage.getItem('Usuario')
    @user_id = @storage.getItem('user_id')
    @logginTime = @storage.getItem('logginTime')
    return @usuario
  
  setUsuario: (usuario,json)->
    @user_id = json.id
    @usuario =  usuario
    @storage.setItem('Usuario',@usuario)
    @storage.setItem('user_id',@user_id)
    @storage.setItem('logginTime',(new Date()).getTime())

  logout: (callback) ->
    @storage.removeItem('Usuario')
    @usuario = null
    @user_id = null
    $.get(@config.logoutURL,callback)

  login: (u,p) =>
    #disable the button so we can't resubmit while we wait
    if (u and  p)
      url = @config.loginURL
      events.trigger(@config.id,User.EVENT_LOGIN_START)
      xhr= ajax.post {
          url:url
          dataType:'json'
          data:
            username:u
            password:p
      }
      xhr.done (json) =>
        if json.error
          alert(json.error)
        else
          @setUsuario u, json
          #dispara mensagem de login com sucesso
          events.trigger(@config.id,User.EVENT_LOGIN_SUCCESS,json)

        events.trigger(@config.id,User.EVENT_LOGIN_FINISH,json)
      xhr.fail (reason) =>
        events.trigger(@config.id,User.EVENT_LOGIN_FAIL,reason)
        
    return false
   

module.exports = {'User':User}
# vim: set ts=2 sw=2 sts=2 expandtab:

