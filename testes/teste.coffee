
SLSAPI = require('../lib/slsapi')

console.log('Teste DataSourceGoogle: ')
api = new SLSAPI( {
  urlConfServico:'http://sl.wancharle.com.br/notebook/5514580391f57bdf0d0ba65b'})
SLSAPI.on('slsapi.config:sucesso', ()->
  xhr = SLSAPI.ajax.get('http://sl.wancharle.com.br/note/553a69b8a7072f36708c03c7')
  xhr.done((data)->
    data = JSON.parse(data)
    data['config']['dataSources']=data['config']['fontes']
    api.config.parseOpcoes(data['config'], true)
    dataPool = new SLSAPI.dataPool.DataPool(api.config)
    dataPool.loadAllData('teste')
    SLSAPI.on('dados:carregados', (id)->
       if (id == api.config.id)
          if dataPool.dataSources[0].notes.length==5
            console.log('ok')
    )
  )
)

# vim: set ts=2 sw=2 sts=2 expandtab:

