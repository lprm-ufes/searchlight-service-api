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
  @EVENT_LOGOUT_SUCCESS = 'userLogoutSuccess.slsapi'
  @EVENT_LOGOUT_FAIL = 'userLogoutFail.slsapi'

  @instances = {} 

  @getInstance: () ->
    return @instances[config.id]

  constructor: (@config)->
    User.instances[@config.id] = @
    @storage = localStorage
    @usuario = this.getUsuario()
    if not @isLogged()
      @logout(true) # logout apenas no cliente
    @config.register(@)

  parseOpcoes: (@opcoes) ->
    @loginURL = @opcoes.get 'loginURL', @loginURL or "#{@config.serverURL}/user/login/"
    @logoutURL = @opcoes.get 'logoutURL', @logoutURL or "#{@config.serverURL}/user/logout/"
    # ps: dont parse user_id because user need be logged first and dont use the user suplied by conf

  toJSON: ()->
    {
      loginURL:@loginURL
      logoutURL:@logoutURL
      user: @user_id
    }


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
    @user_data = @storage.getItem('user_data')
    return @usuario
  
  setUsuario: (usuario,json)->
    @user_id = json.id
    @usuario =  usuario
    @storage.setItem('Usuario',@usuario)
    @storage.setItem('user_id',@user_id)
    @storage.setItem('logginTime',(new Date()).getTime())
    @storage.setItem('user_data',JSON.stringify(json))

  logout: (server) ->
    @storage.removeItem('Usuario')
    @usuario = null
    @user_id = null
    if server
      xhr = ajax.get(@logoutURL)
      xhr.done((req)=> events.trigger(@config.id,User.EVENT_LOGOUT_SUCCESS,req))
      xhr.fail((req)=> events.trigger(@config.id,User.EVENT_LOGOUT_FAIL,req))
  
  logout: (onlyClient) ->
    @storage.removeItem('Usuario')
    @usuario = null
    @user_id = null
    if not onlyClient
      xhr= ajax.get(@logoutURL)
      xhr.done((req)=> events.trigger(@config.id,User.EVENT_LOGOUT_SUCCESS,req))
      xhr.fail((req)=> events.trigger(@config.id,User.EVENT_LOGOUT_FAIL,req))

  login: (u,p) =>
    #disable the button so we can't resubmit while we wait
    if (u and  p)
      url = @loginURL
      events.trigger(@config.id,User.EVENT_LOGIN_START)
      xhr= ajax.post {
          url:url
          dataType:'json'
          data:
            username:u
            password:p
      }
      xhr.done (res) =>
        json = res.body
        if json.error
          alert(json.error)
        else
          @setUsuario u, json
          #dispara mensagem de login com sucesso
          events.trigger(@config.id,User.EVENT_LOGIN_SUCCESS,json)

        events.trigger(@config.id,User.EVENT_LOGIN_FINISH,json)
      xhr.fail (err) =>
        events.trigger(@config.id,User.EVENT_LOGIN_FAIL,err)
        
    return false
   

module.exports = {'User':User}
# vim: set ts=2 sw=2 sts=2 expandtab:

