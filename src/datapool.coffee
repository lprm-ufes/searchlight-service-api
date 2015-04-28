DataSource  = require('./datasource.coffee').DataSource

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
    SLSAPI.on('slsapi:datasource:load',(caller,id)=>
      if id == config.id
        @onDataSourceLoaded()
    )

  addDataSource: (s)->
    source = new DataSource(s.url,s.func_code)
    if source.isValid()
      @dataSources.push(source)

  removeDataSource: (i) ->
    @dataSources.splice(i,1)
 
  getDataSources:() ->
    return @dataSources

  updateFonte: (url,func_code, index) ->
    @dataSources[index].url = url
    @dataSources[index].func_code = func_code

  getDataSource: (i) ->
    return @dataSources[i]

  # load all data from datasources
  loadAllData: (caller) =>
    obj = this
    @sourcesLoaded = 0
    SLSAPI.trigger("dados:carregando",caller)
    for source, i in @dataSources
      source.loadData(false,@config)

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
      SLSAPI.trigger('dados:carregados',@config.id)


module.exports = {DataPool:DataPool}

# vim: set ts=2 sw=2 sts=2 expandtab:

