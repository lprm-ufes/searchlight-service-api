
test = (SLSAPI)->
  describe "SLSAPI", ()->
    api = null 
    describe "#constructor()", (done)->
      it "should return a instance of class SLSAPI", ->
        conf = {}
        api = new SLSAPI(conf)
        api.constructor.name.should.equal 'SLSAPI'

    describe "Config", ->
      it "should to trigger a Config.EVENT_READY for a successful configuration", (done)->
        conf = {urlConfServico:'http://sl.wancharle.com.br/notebook/5514580391f57bdf0d0ba65b'}
        api = new SLSAPI(conf)
        api.on SLSAPI.Config.EVENT_READY, (id)->
          done()

      it "should to trigger a Config.EVENT_FAIL for a failure in configuration", (done)->
        apif = new SLSAPI({urlConfServico:'http://wrongsite/notebook/5514580391f57bdf0d0ba65b'})

        apif.on SLSAPI.Config.EVENT_FAIL, (id)->
          done()

      it "should have a coletorNotebookId after parseOpcoes with a urlConfServico option" , (done)->
        conf = {urlConfServico:'http://sl.wancharle.com.br/notebook/5514580391f57bdf0d0ba65b'}
        api = new SLSAPI(conf)
        api.on SLSAPI.Config.EVENT_READY, (id)->
          api.config.coletorNotebookId.should.equal('5514580391f57bdf0d0ba65b')
          done()

    describe "User", ->
      api =null
      before (done)->
        conf = {urlConfServico:'http://sl.wancharle.com.br/notebook/5514580391f57bdf0d0ba65b'}
        api = new SLSAPI(conf)
        api.on SLSAPI.Config.EVENT_READY, (id)->
          done()

      describe "login", ->
        it "should allow to login a user with correct credentials", (done)->
          api.user.login('wan','123456')
          api.on(SLSAPI.User.EVENT_LOGIN_FINISH,(err)->
            done())

        it "and save the logged user to localStorage", ->
          api.user.getUsuario().should.equal('wan')
        
        it "should to trigger User.EVENT_LOGIN_FAIL for incorrect credentials", (done)->
          api.user.login('wan','nopassword')
          api.on(SLSAPI.User.EVENT_LOGIN_FAIL,(req)->
            JSON.parse(req.response.body).error.should.equal('Invalid password')
            done())
 
      describe "logout", ->
        it "should allow to logout a logged user", (done)->
          api.user.logout()
          api.on SLSAPI.User.EVENT_LOGOUT_SUCCESS, ()-> done()

        it "and clear the saved user from localStorage", ->
          (api.user.getUsuario()==null).should.to.be.true

        it "should to trigger User.EVENT_LOGOUT_FAIL for a failure in logout", (done)->
          conf = {
            logoutURL : 'http://wrongsite.com.br/dont/work/logout/'
            urlConfServico:'http://sl.wancharle.com.br/notebook/5514580391f57bdf0d0ba65b'}
          api2 = new SLSAPI(conf)
          api2.on SLSAPI.Config.EVENT_READY, (id)->
            api2.user.logout()
            api2.on SLSAPI.User.EVENT_LOGOUT_FAIL, (req)->console.log(req); done()

    describe "Notes", ->
    describe "Notebook", ->
    describe "DataPool", ->
      describe "DataSource", ->
      describe "DataSourceCSV", ->
      describe "DataSourceGoogle", ->
      


    

if typeof process.browser != 'undefined'
  window.slsapiTest = test


module.exports = {test:test}

# vim: set ts=2 sw=2 sts=2 expandtab:

