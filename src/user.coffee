class User
  @instances = {} 

  @getInstance: (config) ->
    return @instances[config.id]

  constructor: (@config)->
    User.instances[@config.id] = @
    @storage = window.localStorage
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
   

module.exports = {'User':User}
# vim: set ts=2 sw=2 sts=2 expandtab:

