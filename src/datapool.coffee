events = require './events'
DataSource  = require('./datasource').DataSource
DataSourceGoogle  = require('./datasourceGoogle').DataSourceGoogle
DataSourceCSV  = require('./datasourceCSV').DataSourceCSV

createDataSource = (url,functionCode)->
  if url.indexOf("docs.google.com/spreadsheet") > -1
    return new DataSourceGoogle(url,functionCode)
  else
    if url.slice(-4)==".csv"
      return new DataSourceCSV(url,functionCode)
    else
      return new DataSource(url,functionCode)

createDataPool = (config)->
  instance = DataPool.getInstance(config)
  if instance
    instance.destroy()
  instance = new DataPool()
  instance._constructor(config)
  return instance



class DataPool

  @EVENT_LOAD_START = 'datapool:start.slsapi'
  @EVENT_LOAD_STOP = 'datapool:stop.slsapi'

  @instances = {}

  @getInstance: (config) ->
    return @instances[config.id]

  _constructor: (config) ->
    DataPool.instances[config.id] = @
    @config = config

    @dataSources = []

    # adicionando fontes 
    dataSources = @config.dataSources
    for s, index in dataSources
      @addDataSource(s)

    # bind counter function to count DataSources loaded
    events.on(config.id,DataSource.EVENT_LOADED,()=>
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
  loadAllData: () =>
    obj = this
    @sourcesLoaded = 0
    events.trigger(@config.id,DataPool.EVENT_LOAD_START)
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
      events.trigger(@config.id,DataPool.EVENT_LOAD_STOP,@)

  destroy: ->
    #unregiser all events 
    events.off(@config.id,DataSource.EVENT_LOADED)
    events.off(@config.id,DataPool.EVENT_LOAD_START)
    events.off(@config.id,DataPool.EVENT_LOAD_STOP)



module.exports = {DataPool:DataPool,createDataPool:createDataPool}

# vim: set ts=2 sw=2 sts=2 expandtab:

