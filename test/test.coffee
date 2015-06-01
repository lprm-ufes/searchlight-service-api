genericFail = (err)->
  if typeof err == 'string'
    console.log err
  else
    console.log err.response.body

test = (SLSAPI)->
  describe "SLSAPI", ->
    api = null 
    describe "#constructor()", (done)->
      it "should return a instance of class SLSAPI", ->
        conf = {}
        api = new SLSAPI(conf)
        api.constructor.name.should.equal 'SLSAPI'

    describe "Config", ->
      it "should triggering a Config.EVENT_READY for a successful configuration", (done)->
        conf = {urlConfServico:'http://sl.wancharle.com.br/mashup/5567935895b248224048e517'}
        api = new SLSAPI(conf)
        api.on SLSAPI.Config.EVENT_READY, (id)->
          done()

      it "should triggering a Config.EVENT_FAIL for a failure in configuration", (done)->
        apif = new SLSAPI({urlConfServico:'http://wrongsite/mashup/5514580391f57bdf0d0ba65b'})

        apif.on SLSAPI.Config.EVENT_FAIL, (id)->
          done()

      it "should have a mashup id after parseOpcoes with a urlConfServico option" , (done)->
        conf = {urlConfServico:'http://sl.wancharle.com.br/mashup/5567935895b248224048e517'}
        api = new SLSAPI(conf)
        api.on SLSAPI.Config.EVENT_READY, (id)->
          api.mashup.id.should.equal('5567935895b248224048e517')
          done()

      it "should generate config from children classes like datapool", (done)->
        conf = {
          dataSources: [
            url:"http://sl.wancharle.com.br/note/?limit=10"
            func_code: "function ala(item){return item}"
          ]
          }
        api = new SLSAPI(conf)
        api.on SLSAPI.Config.EVENT_READY, (id)->
          api.config.toJSON().should.not.have.property('dataSources')
          dataPool = SLSAPI.dataPool.createDataPool(api.mashup)
          api.config.toJSON().should.have.property('dataSources')
          done()

    describe "User", ->
      api =null
      before (done)->
        conf = {}
        api = new SLSAPI(conf)
        api.on SLSAPI.Config.EVENT_READY, (id)->
          done()

      describe "login", ->
        it "should allow login a user with correct credentials", (done)->
          api.user.login('wan','123456')
          api.on(SLSAPI.User.EVENT_LOGIN_FINISH,(err)->
            done())

        it "and save the logged user to localStorage", ->
          api.user.getUsuario().should.equal('wan')
        
        it "should triggering User.EVENT_LOGIN_FAIL for incorrect credentials", (done)->
          api.user.login('wan','nopassword')
          api.on(SLSAPI.User.EVENT_LOGIN_FAIL,(req)->
            req.response.body.error.should.equal('Invalid password')
            done())
 
      describe "logout", ->
        it "should allow logout a logged user", (done)->
          api.user.logout()
          api.on SLSAPI.User.EVENT_LOGOUT_SUCCESS, ()-> done()

        it "and clear the saved user from localStorage", ->
          (api.user.getUsuario()==null).should.to.be.true

        it "should to trigger User.EVENT_LOGOUT_FAIL for a failure in logout", (done)->
          conf = {logoutURL : 'http://sl.wancharle.com.br/dont/work/logout/'}
          api2 = new SLSAPI(conf)
          api2.on SLSAPI.Config.EVENT_READY, (id)->
            api2.user.logout()
            api2.on SLSAPI.User.EVENT_LOGOUT_FAIL, (req)->
              done()
      
    describe "Notebook", ->
      api =null
      notebookid=0

      before (done)->
        conf = {}
        api = new SLSAPI(conf)
        api.on SLSAPI.Config.EVENT_READY, (id)->
          api.user.login('wan','123456')
          api.on(SLSAPI.User.EVENT_LOGIN_FINISH,(err)->
            done())

      it 'should allow creating a notebook on StorageService', (done) ->
        ok = (notebook) ->
          if notebook.name == 'notebook teste'
            notebookid =  notebook.id
            done()
        api.notebook.create('notebook teste', ok, genericFail)

      it 'should allow reading a notebook by name', (done)->
        ok = (notebook) ->
          if notebook[0].name == 'notebook teste'
            notebookid = notebook[0].id
            done()
        api.notebook.getByName('notebook teste', ok,(err)->console.log err.response)

      it 'should allow reading a notebook by id', (done)->
        ok = (notebook) ->
          if notebook.id == notebookid
            done()
        api.notebook.getById(notebookid, ok,(err)->console.log err.response)

      it 'should allow updating a notebook on StorageService', (done) ->
        ok = (notebook) ->
          if notebook.name == 'notebook updated'
            done()
        api.notebook.getByName('notebook updated'
          ,(notebook)->
            api.notebook.update(notebookid,{name: 'notebook updated'}, ok, genericFail)
          ,genericFail)
 
      it  'should allow deleting a notebook on StorageService', (done) ->
        ok = (notebook) ->
          if notebook.name == 'notebook updated'
            done()
        api.notebook.getByName('notebook updated'
          ,(notebook)->
            api.notebook.delete(notebook[0].id, ok, genericFail)
          ,genericFail)
        
 
    describe "Mashup", ->
      api = null
      updated_at = ''
      before (done)->
        conf = {mashup:true}
        api = new SLSAPI(conf)
        api.on SLSAPI.Config.EVENT_READY, (id)->
          api.user.login('wan','123456')
          api.on(SLSAPI.User.EVENT_LOGIN_FINISH,(err)->
            done())

      it 'should allow creating a mashup on storageService',(done)->
        api.mashup.title = 'teste de salvamento de conf'
        success = (mashupSaved)->
          updated_at = mashupSaved.updatedAt
          done()
        api.mashup.save(success,genericFail)

      it 'should allow updating a mashup on storageService',(done)->
        api.mashup.title = 'teste de salvamento de conf'
        success = (mashupSaved)->
          mashupSaved.updatedAt.should.not.equal(updated_at)
          done()
        api.mashup.save(success,genericFail)

      it 'should allow associating a notebook with the mashup', (done)->
        api.notebook.get((notebooks)->
          id = notebooks[0].id
          api.notes.storageNotebook = id
          success = (mashupSaved)->
           mashupSaved.storageNotebook.id.should.equal(id)
           done()
          api.mashup.save(success,genericFail)
        ,genericFail)


      it 'should allow deleting a mashup on storageService',(done)->
        api.mashup.title = 'teste de salvamento de conf'
        success = (url)->
          done()
        api.mashup.get(api.mashup.title,api.user.user_id
          ,(found)->
            api.mashup.delete(found.id,success, genericFail)
          ,genericFail)

     

    describe "Notes", ->
      api =null
      noteAdded = '555275afe3a4c71a6d9605b2'
      before (done)->
        conf = {urlConfServico:'http://sl.wancharle.com.br/note/555502050829091e5f7cf72c'}
        api = new SLSAPI(conf)
        api.on SLSAPI.Config.EVENT_READY, (id)->
          api.user.login('wan','123456')
          api.on SLSAPI.User.EVENT_LOGIN_FINISH, ->
            done()


      it "should allow creating the notes for a logged user", (done)->
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

      it 'should allow reading the notes by query', (done)->
        api.notes.getByQuery(
          'comentarios=test-addnote'
          ,(notes)->
              note = notes[0]
              note.id.should.be.equal(noteAdded)
              done()
          ,(err)->
              console.log(err))

      it 'should allow reading the notes by user', (done)->
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

      it 'should allow updating a note', (done) ->
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

      it 'should allow deleting a note owned by logged user', (done)->
        api.notes.delete(noteAdded,(res)->
          if res.body.id
            done()
          else
            console.log res.body
          )
        
    describe 'DataPool', ->
      before (done)->
        conf = {}
        api = new SLSAPI(conf)
        api.on SLSAPI.Config.EVENT_READY, (id)->
          done()

      describe 'DataSource', ->
        it 'should load  data in json format from "text/plain" response', (done)->
          @timeout( 10000)
          conf = {
            dataSources: [
              url: "http://wancharle.com.br/sl/portoalegre.cc.json",
              func_code: "function convert_item_porto(item){\n
              item_convertido = {} ;
              item = item['cause']\n
              ;item_convertido.longitude = \"\"+item.longitude\n
              ;item_convertido.latitude = \"\" +item.latitude\n
              ;item_convertido.title = item.title\n
              ;item_convertido.texto =item.title+\"<br>Data: \"+item.updated_at\n\t
              ;  return item_convertido;
              } "
            ]
          }
          api.config.parseOpcoes(conf,true)
          dataPool = SLSAPI.dataPool.createDataPool(api.mashup)
          dataPool.loadAllData()
          api.off(SLSAPI.dataPool.DataPool.EVENT_LOAD_STOP)
          api.on(SLSAPI.dataPool.DataPool.EVENT_LOAD_STOP, (datapool)->
            datapool.dataSources[0].notes.length.should.equal(1411)
            done()
          )
          
        it 'should load  data in json format from "application/json" response', (done)->
          conf = {
            dataSources: [
              url:"http://sl.wancharle.com.br/note/?limit=10"
              func_code: "function ala(item){return item}"
            ]
            }
          api.config.parseOpcoes(conf,true)
          dataPool = SLSAPI.dataPool.createDataPool(api.mashup)
          dataPool.loadAllData()
          api.off(SLSAPI.dataPool.DataPool.EVENT_LOAD_STOP)
          api.on(SLSAPI.dataPool.DataPool.EVENT_LOAD_STOP, (datapool)->
            datapool.dataSources[0].notes.length.should.equal(10)
            done()
          )

        it 'should load data from especific data source only', (done)->
          conf = {
            dataSources: [
              {url:"http://sl.wancharle.com.br/note/?limit=10", func_code: "function ala(item){return item}"},
              {url: "http://wancharle.com.br/sl/portoalegre.cc.json", func_code: "function convert_item_porto(item){\n
              item_convertido = {} ; item = item['cause']\n  ;item_convertido.longitude = \"\"+item.longitude\n
              ;item_convertido.latitude = \"\" +item.latitude\n ;item_convertido.title = item.title\n
              ;item_convertido.texto =item.title+\"<br>Data: \"+item.updated_at\n\t ;  return item_convertido;
              } "}
            ]
            }
          api.config.parseOpcoes(conf,true)
          dataPool = SLSAPI.dataPool.createDataPool(api.mashup)
          dataPool.loadOneData(1)
          api.off(SLSAPI.dataPool.DataPool.EVENT_LOAD_STOP)
          api.on(SLSAPI.dataPool.DataPool.EVENT_LOAD_STOP, (datapool)->
            datapool.dataSources[1].notes.length.should.equal(1411)
            done()
          )
        

        it 'should load data from cache with forceImport=True', (done)->
          @timeout(10000)
          conf = {
            id:'5567935895b248224048e517' # mashupid portoalegre.json
            dataSources: [
              url:"http://wrong/note/" # proposital wrong url to prove who load from cache ... 
              func_code: "function (item){return null}" # proposital wrong funciton
              ]}
          api.config.parseOpcoes(conf,true)
          dataPool = SLSAPI.dataPool.createDataPool(api.mashup)
          dataPool.loadAllData(true) # force true 
          api.off(SLSAPI.dataPool.DataPool.EVENT_LOAD_STOP)
          api.on(SLSAPI.dataPool.DataPool.EVENT_LOAD_STOP, (datapool)->
            datapool.dataSources[0].notes.length.should.equal(1000)
            done()
          )
        
        it 'should load data from cache without forceImport', (done)->
          @timeout(10000)
          conf = {
            id:'5567935895b248224048e517' # mashup id portoalegre.json
            dataSources: [
              url:"http://wrong/note/" # proposital wrong url to prove who load from cache ... 
              func_code: "function (item){return null}" # proposital wrong funciton
              ]}
          api.config.parseOpcoes(conf,true)
     
          dataPool = SLSAPI.dataPool.createDataPool(api.mashup)
          dataPool.loadAllData() # force true 

          api.off(SLSAPI.dataPool.DataPool.EVENT_LOAD_STOP)
          api.on(SLSAPI.dataPool.DataPool.EVENT_LOAD_STOP, (datapool)->
            datapool.dataSources[0].notes.length.should.equal(1000)
            done()
          )

        it 'should not load data from cache if it already is from a searchlight server', (done)->
          @timeout(10000)
          conf = {
            id:'5567928b95b248224048e516' #mashuptittle: possui 2 items...'nonotebook name = lprm_teste
            dataSources: [ 
              url: "http://wancharle.com.br/sl/portoalegre.cc.json", func_code: "function (item){\n
            item_convertido = {} ; item = item['cause']\n  ;item_convertido.longitude = \"\"+item.longitude\n
            ;item_convertido.latitude = \"\" +item.latitude\n; return item_convertido;
            } "
            ]
          }
          api.config.parseOpcoes(conf,true)
          dataPool = SLSAPI.dataPool.createDataPool(api.mashup)
          dataPool.loadAllData()
          api.off(SLSAPI.dataPool.DataPool.EVENT_LOAD_STOP)
          api.on(SLSAPI.dataPool.DataPool.EVENT_LOAD_STOP, (datapool)->
            datapool.dataSources[0].notes.length.should.equal(1411)
            done()
          )
          
        it 'should load data from original url if load from cache fail', (done)->
          @timeout(10000)
          conf = {
            id:'555502050829' #mashup id wrong cache fail
            dataSources: [
              url: "http://wancharle.com.br/sl/portoalegre.cc.json", func_code: "function (item){\n
              item_convertido = {} ; item = item['cause']\n  ;item_convertido.longitude = \"\"+item.longitude\n
              ;item_convertido.latitude = \"\" +item.latitude\n; return item_convertido;
              } "
            ]           }
          api.config.parseOpcoes(conf,true)
          dataPool = SLSAPI.dataPool.createDataPool(api.mashup)
          dataPool.loadAllData()
          api.on(SLSAPI.dataPool.DataPool.EVENT_LOAD_STOP, (datapool)->
            datapool.dataSources[0].notes.length.should.equal(1411)
            done()
          )

      describe 'DataSourceGoogle', ->
        it 'should load a spreadsheet from google drive with 5 valid elements', (done)->
          configGoogle = {
            noteid:false # necessario para apagar a conf do test anterior
            dataSources: [
                url: 'https://docs.google.com/spreadsheet/pub?key=0AhU-mW4ERuT5dHBRcGF5eml1aGhnTzl0RXh3MHdVakE&single=true&gid=0&output=html'
                func_code: 'function (item) {\n return item;\n }'
            ]
          }
          api.config.parseOpcoes(configGoogle,true)
          dataPool = SLSAPI.dataPool.createDataPool(api.mashup)
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
          dataPool = SLSAPI.dataPool.createDataPool(api.mashup)
          dataPool.loadAllData()

          api.on(SLSAPI.dataPool.DataPool.EVENT_LOAD_STOP, (datapool)->
          
            datapool.dataSources[0].notes.length.should.equal(14472)
            done()
          )



if typeof process.browser != 'undefined'
  window.slsapiTest = test


module.exports = {test:test}

# vim: set ts=2 sw=2 sts=2 expandtab:

