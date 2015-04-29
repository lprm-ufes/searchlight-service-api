events = require './events'
DataSource  = require('./datasource').DataSource
DataSourceGoogle  = require('./datasourceGoogle').DataSourceGoogle

createDataSource = (url,functionCode)->
  if url.indexOf("docs.google.com/spreadsheet") > -1
    return new DataSourceGoogle(url,functionCode)
  else
    return new DataSource(url,functionCode)


class DataPool
  @instances = {}

  @getInstance: (config) ->
    return @instances[config.id]

  constructor: (config) ->
    DataPool.instances[config.id] = @
    @config = config

    @dataSources = []

    # adicionando fontes 
    dataSources = @config.dataSources
    for s, index in dataSources
      @addDataSource(s)

    # bind counter function to count DataSources loaded
    events.on('slsapi:datasource:load',(id)=>
      if id == config.id
        @onDataSourceLoaded()
    )

  addDataSource: (s)->
    source = createDataSource(s.url,s.func_code)
    if source.isValid()
      @dataSources.push(source)

  removeDataSource: (i) ->
    @dataSources.splice(i,1)
 
  getDataSources:() ->
    return @dataSources

  updateFonte: (url,func_code, index) ->
    @dataSources[index] = createDataSource(url,func_code)

  getDataSource: (i) ->
    return @dataSources[i]

  # load all data from datasources
  loadAllData: (callerId) =>
    obj = this
    @sourcesLoaded = 0
    events.trigger("dados:carregando",callerId)
    for source, i in @dataSources
      source.loadData(@config,false)

  # retorna json que será salvo na configuração deste datapool
  toJSON:() ->
    array = []
    for f,i in @dataSources
      f.func_code = f.func_code.toString()
      array.push(f)
    return array

  onDataSourceLoaded: ()->
    @sourcesLoaded +=1
    if @sourcesLoaded == @dataSources.length
      events.trigger('dados:carregados',@config.id)


module.exports = {DataPool:DataPool}

# vim: set ts=2 sw=2 sts=2 expandtab:

