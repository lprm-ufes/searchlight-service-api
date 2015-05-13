
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

      it 'should update a note', (done) ->
        changes = { categoria:'update'}
        ok = (res)->
          api.notes.getByQuery("id="+noteAdded
            ,(res)->
              if res.categoria == 'update'
                done()
            ,(err)->
              console.log(err))
        fail = (err) -> console.log err.response
        api.notes.update(noteAdded,changes,ok,fail)

      it 'should allow to del note owned by logged user', (done)->
        api.notes.delete(noteAdded,(res)->
          if res.body.id
            done()
          else
            console.log res.body
          )
        
    describe "Notebook", ->
      api =null
      notebookid=0

      before (done)->
        conf = {}
        api = new SLSAPI(conf)
        api.on SLSAPI.Config.EVENT_READY, (id)->
          done()

      it 'should get notebook by name', (done)->
        ok = (notebook) ->
          if notebook[0].name == 'mapas'
            notebookid = notebook[0].id
            done()
        api.notebook.getByName('mapas', ok,(err)->console.log err.response)

      it 'should get notebook by id', (done)->
        ok = (notebook) ->
          if notebook.id == notebookid
            done()
        api.notebook.getById(notebookid, ok,(err)->console.log err.response)

    describe 'DataPool', ->
      before (done)->
        conf = {}
        api = new SLSAPI(conf)
        api.on SLSAPI.Config.EVENT_READY, (id)->
          done()


      describe 'DataSourceGoogle', ->
        it 'should load a spreadsheet from google drive with 5 valid elements', (done)->
          configGoogle = {
            dataSources: [
                url: 'https://docs.google.com/spreadsheet/pub?key=0AhU-mW4ERuT5dHBRcGF5eml1aGhnTzl0RXh3MHdVakE&single=true&gid=0&output=html'
                func_code: 'function (item) {\n return item;\n }'
            ]
          }
          api.config.parseOpcoes(configGoogle,true)
          dataPool = SLSAPI.dataPool.createDataPool(api.config)
          dataPool.loadAllData()
          api.on(SLSAPI.dataPool.DataPool.EVENT_LOAD_STOP, (datapool)->
            datapool.dataSources[0].notes.length.should.equal(5)
            done()
          )

      describe 'DataSourceCSV', ->
        it 'should load a CSV file with 14472 valid elements', (done)->
          @timeout( 100000)
          configCSV =
            dataSources: [
              url: 'http://wancharle.com.br/sl/PAC_2014_04.csv',
              func_code: "function convert_item_pac(item){\n        item_convertido = {}\n        //console.log('1');\n        //console.log(item_convertido);\n        if ((item.val_lat) && (item.val_long)&&(item.val_lat.length > 0) && (item.val_long.length > 0)){\n        latlog = dms2decPTBR(item.val_lat,item.val_long)\n        //if (isNaN(latlog[0]) || isNaN(latlog[1])){\n        //    return null;\n      //  }\n        item_convertido.longitude = \"\"+latlog[1]\n        item_convertido.latitude = \"\" +latlog[0]\n        item_convertido.texto = item.dsc_titulo\n        item_convertido.cat = item.idn_estagio+\"%\";\n         }else{\n             return null;\n             }\n        //console.log(item_convertido);\n        //item_convertido.cat = item.cause.category_name\n        //item_convertido.icon = Icones[item_convertido.cat_id]\n        return item_convertido \n    }"
            ]
          api.config.parseOpcoes(configCSV,true)
          dataPool = SLSAPI.dataPool.createDataPool(api.config)
          dataPool.loadAllData()

          api.on(SLSAPI.dataPool.DataPool.EVENT_LOAD_STOP, (datapool)->
          
            datapool.dataSources[0].notes.length.should.equal(14472)
            done()
          )



if typeof process.browser != 'undefined'
  window.slsapiTest = test


module.exports = {test:test}

# vim: set ts=2 sw=2 sts=2 expandtab:

