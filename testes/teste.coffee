
apid = api = 0
if typeof process.browser == 'undefined' 
  SLSAPI = require('../lib/slsapi')
else
  SLSAPI = require('../src/slsapi')


teste = (texto,noteid,total,next)->
  xhr = SLSAPI.ajax.get("http://sl.wancharle.com.br/note/#{noteid}")# )
  xhr.done((data)->
    console.log(texto)
    data['config']['dataSources']=data['config']['fontes']
    apid.config.parseOpcoes(data['config'], true)
    dataPool = SLSAPI.dataPool.createDataPool(apid.config)
    dataPool.loadAllData()
    
    apid.on(SLSAPI.dataPool.DataPool.EVENT_LOAD_STOP, (datapool)->
      if datapool.dataSources[0].notes.length==total
        console.log('OK --> [',total,'itens ]')
        if next
          next()
      else
        console.error('fail',datapool.dataSources[0].notes.length,total)
    )
  )
  xhr.fail((error)-> console.log("error ao baixar config"))

testeGoogle = ()->
  teste('Testando DataSourceGoogle','553a69b8a7072f36708c03c7',5,null)

testeCSV = ()->
  teste('Testando DataSourceCSV','554a9cc0d80060fa448d8b2f',14472,()->testeGoogle())#testeGoogle)

testemain = ()->
  console.log('\nTestes de dados:')
  apid = new SLSAPI( {
    urlConfServico:'http://sl.wancharle.com.br/notebook/5514580391f57bdf0d0ba65b',nameSpace:'teste'})

  apid.on(SLSAPI.Config.EVENT_READY, (a)->
      testeCSV()
  )

testelogin2 = ()->
  api.user.login('wan','123456')
  api.on(SLSAPI.User.EVENT_LOGIN_SUCCESS,(teste)->
    console.log('login\nOK --> [', teste.username, ']') 
    testemain()
  )
  api.on(SLSAPI.User.EVENT_LOGIN_FAIL,(reason)->
      console.log('login Fail', reason.response.body,reason.response.statusCode) 
  )

testelogin = ()->
  console.log('Testes de acesso:')
  api = new SLSAPI({urlConfServico:'http://sl.wancharle.com.br/notebook/5514580391f57bdf0d0ba65b'})
  nbId = null
  SLSAPI.debug=true
  api.on(SLSAPI.Config.EVENT_READY, (id)->
    notebook_name = 'lprm_teste '
    api.notebook.getByName(notebook_name,
    (data)->
       if data.length >0 
         nbId=data[0].id
         console.log('buscando notebookID \nOK --> [',nbId, ']')
         testelogin2()
       else
         console.error("ERROR --> notebook '#{notebook_name}' not found!" )

    ,(error)->
       console.error('ERRORR -->', error)
       console.log('não existe repositório com este nome')
    )
  )
  return api


if typeof process.browser == 'undefined'
  testelogin()
else
  window.testemain = testemain
  window.testelogin= testelogin


# vim: set ts=2 sw=2 sts=2 expandtab:

