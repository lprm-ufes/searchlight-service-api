
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
      describe "login", ->
        it "should allow to login a user with correct credentials", ->
        it "or to trigger User.EVENT_LOGIN_FAIL for incorrect credentials", ->
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

