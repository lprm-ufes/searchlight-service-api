events = require './events'
DataSource  = require('./datasource').DataSource
DataSourceGoogle  = require('./datasourceGoogle').DataSourceGoogle
DataSourceCSV  = require('./datasourceCSV').DataSourceCSV

createDataSource = (url,functionCode,i)->
  if url.indexOf("docs.google.com/spreadsheet") > -1
    return new DataSourceGoogle(url,functionCode,i)
  else
    if url.slice(-4)==".csv"
      return new DataSourceCSV(url,functionCode,i)
    else
      return new DataSource(url,functionCode,i)

createDataPool = (mashup)->
  instance = DataPool.getInstance(mashup.config)
  if instance
    instance.destroy()
  instance = new DataPool()
  instance._constructor(mashup)
  return instance



class DataPool

  @EVENT_LOAD_START = 'datapool:start.slsapi'
  @EVENT_LOAD_STOP = 'datapool:stop.slsapi'

  @instances = {}

  @getInstance: (config) ->
    return @instances[config.id]

  parseOpcoes:(opcoes)->
    @dataSourcesConf = opcoes.get 'dataSources', @dataSourcesConf or []
    @dataSources = []

    # adicionando fontes 
    for s, index in @dataSourcesConf
      @addDataSource(s)

    # bind counter function to count DataSources loaded
    events.off(@config.id,DataSource.EVENT_LOADED)
    events.on(@config.id,DataSource.EVENT_LOADED,()=>
        @onDataSourceLoaded()
    )

  # retorna json que será salvo na configuração deste datapool
  toJSON:() ->
    return { 'dataSources': ds.toJSON() for ds in @dataSources}



  _constructor: (@mashup) ->
    DataPool.instances[@mashup.config.id] = @
    @config = @mashup.config
    @config.register(@)

  addDataSource: (s)->
    source = createDataSource(s.url,s.func_code,@dataSources.length)
    if source.isValid()
      @dataSources.push(source)

  removeDataSource: (i) ->
    @dataSources.splice(i,1)
 
  getDataSources:() ->
    return @dataSources

  updateDataSource: (url,func_code, index) ->
    @dataSources[index] = createDataSource(url,func_code,index)

  getDataSource: (i) ->
    return @dataSources[i]
  
  # load one especific datasource from datasources
  loadOneData: (fonteIndex,force="",position) ->
    @loadingOneData = true
    events.trigger(@config.id,DataPool.EVENT_LOAD_START)
    @dataSources[fonteIndex].load(@mashup,force,position)

  # load all data from datasources
  loadAllData: (force="",position) =>
    @sourcesLoaded = 0
    events.trigger(@config.id,DataPool.EVENT_LOAD_START)
    for source, i in @dataSources
      source.load(@mashup,force,position)

  onDataSourceLoaded: ()->
    if @loadingOneData
      @loadingOneData = false
      events.trigger(@config.id,DataPool.EVENT_LOAD_STOP,@)
      return
    else
      @sourcesLoaded +=1
      if @sourcesLoaded == @dataSources.length
        events.trigger(@config.id,DataPool.EVENT_LOAD_STOP,@)

  destroy: ->
    #unregiser all events 

    @config.unregister(@)
    events.off(@config.id,DataSource.EVENT_LOADED)
    events.off(@config.id,DataPool.EVENT_LOAD_START)
    events.off(@config.id,DataPool.EVENT_LOAD_STOP)



module.exports = {DataPool:DataPool,createDataPool:createDataPool}

# vim: set ts=2 sw=2 sts=2 expandtab:

