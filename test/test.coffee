
test = (SLSAPI)->
  describe "SLSAPI", ->
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

    describe "User", (doneuser)->
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
            req.response.body.error.should.equal('Invalid password')
            done())
 
      describe "logout", ->
        it "should allow to logout a logged user", (done)->
          api.user.logout()
          api.on SLSAPI.User.EVENT_LOGOUT_SUCCESS, ()-> done()

        it "and clear the saved user from localStorage", ->
          (api.user.getUsuario()==null).should.to.be.true

        it "should to trigger User.EVENT_LOGOUT_FAIL for a failure in logout", (done)->
          conf = {
            logoutURL : 'http://sl.wancharle.com.br/dont/work/logout/'
            urlConfServico:'http://sl.wancharle.com.br/notebook/5514580391f57bdf0d0ba65b'}
          api2 = new SLSAPI(conf)
          api2.on SLSAPI.Config.EVENT_READY, (id)->
            api2.user.logout()
            api2.on SLSAPI.User.EVENT_LOGOUT_FAIL, (req)->
              done()

    describe "Notes", ->
      api =null
      noteAdded = '555275afe3a4c71a6d9605b2'
      before (done)->
        conf = {urlConfServico:'http://sl.wancharle.com.br/notebook/5514580391f57bdf0d0ba65b'}
        api = new SLSAPI(conf)
        api.on SLSAPI.Config.EVENT_READY, (id)->
          api.user.login('wan','123456')
          api.on SLSAPI.User.EVENT_LOGIN_FINISH, ->
            done()


      it "should allow to add notes to logged user", (done)->
        ob = {}
        ob.comentarios = "test-addnote"
        ob.categoria = "test"
        ob.user= api.user.user_id
        ob.latitude = 40.0
        ob.longitude = 20.0
        api.notes.enviar(ob)
        api.on SLSAPI.Notes.EVENT_ADD_NOTE_FINISH, (res)-> 
          noteAdded = res.id
          done()

      it 'should allow to get notes by query', (done)->
        api.notes.getByQuery(
          'comentarios=test-addnote'
          ,(notes)->
              note = notes[0]
              note.id.should.be.equal(noteAdded)
              done()
          ,(err)->
              console.log(err))

      it 'should allow to get notes by user', (done)->
        api.notes.getByUser(
          api.user.user_id
          ,(notes)->
            for n in notes
              if n.user.id != api.user.user_id
                return
            done()
          ,(err)->
            console.log err
          )

      it 'should update a note', ->
        0.should.to.be.null
      it 'should allow to del note owned by logged user', (done)->
        api.notes.delete(noteAdded,(res)->
          if res.body.id
            done()
          else
            console.log 'ai',res.body
          )
        


if typeof process.browser != 'undefined'
  window.slsapiTest = test


module.exports = {test:test}

# vim: set ts=2 sw=2 sts=2 expandtab:

