events = require './events'
ajax = require './ajax'
utils = require './utils'
contexto = {}

contexto = utils 

class DataSource

  @EVENT_LOADED = 'datasourceLoaded.slsapi'
  @EVENT_LOAD_FAIL = 'datasourceLoadFail.slsapi'
  @EVENT_REQUEST_FAIL = 'datasourceRequestFail.slsapi'
  
  @hashItem:(item)->
    return "#{parseFloat(item.latitude).toFixed(7)}#{parseFloat(item.longitude).toFixed(7)}#{utils.md5(JSON.stringify(item))}"

  constructor: (url,func_code,i)->
    @index = i
    # process and validate the datasource
    @valid = true
    if url and typeof func_code is 'function'
      @url = url
      @func_code = func_code
    else
      if typeof func_code is 'string'
        try
          @func_code = utils.string2function(func_code)
          @url = url
        catch e
          console.error e,'Error ao tentar criar funcao de conversao apartir de texto'
          @valid = false
      else
        console.error "Error de configuração de fonte:",{url:url,func_code:func_code}
        @valid = false

    # store the notes and cache's information
    @notes = []
    @notesChildren = {}
    @categories = {}
    @categories_id = {}
    @cachedSource = {url: url, func_code: (i)-> return i}

  # check if the data source is valid
  isValid: ->
    return @valid

  # return or create the list of itens in categorie i.cat
  _getCatOrCreate: (i)=>
    cat=@categories[i.cat]
    if cat
      return cat
    else
      @categories[i.cat] = []
      @categories_id[i.cat] = i.cat_id
      return @categories[i.cat]

  # convert, store e taxomize each note 
  addItem : (i,func_convert) =>
    try
      geoItem = func_convert(i,contexto)
    catch e 
      console.error("Erro em DataSource::addItem: #{e.message}",i)
      geoItem = null
          
    if geoItem
      # se o objeto nao tiver id um hashid eh gerado.
      # mas caso tenha ele eh substitituido pelo hashid para nao gerar conflitos com os ids de armazenamento no banco
      if not geoItem.id
       geoItem.hashid = DataSource.hashItem(geoItem)
      else 
       if not geoItem.hashid
         geoItem.hashid = geoItem.id
       geoItem.id = undefined

      @notes.push(geoItem)
      if geoItem.id_parent
        @addChild(geoItem.id_parent,geoItem)

      cat = @_getCatOrCreate(geoItem)
      cat.push(geoItem)
    return geoItem

  # taxonomize the notes
  addChild: (parentId,child) ->
    if not @notesChildren[parentId]
      @notesChildren[parentId] = [ ]
    @notesChildren[parentId].push(child)

  load: (config,force="") ->
    if config.noteid 
      if @cachedURL
        @loadFromCache(config)
      else
        @getCachedURL(config,force,()=>@loadFromCache(config))
    else
      @loadData(config)

  # load data to dataSource from the datasource.url
  loadData: (config) ->
    xhr = ajax.get(@url,{type:'json'})
    xhr.done (res)=> 
      json = res.body
      if res.type.toLowerCase().indexOf("text") > -1
        json = JSON.parse(res.text)
      @onDataLoaded(json,@,config)

    xhr.fail (err)-> events.trigger(config.id,DataSource.EVENT_REQUEST_FAIL,err)
 
  loadFromCache: (config)->
    url ="#{@cachedURL}&limit=1000 "
    xhr = ajax.get(url,{type:'json'})
    xhr.done (res)=>
      json = res.body
      if res.type.toLowerCase().indexOf("text") > -1
        json = JSON.parse(res.text)
      @onDataLoaded(json,@cachedSource,config)

    xhr.fail (err)-> events.trigger(config.id,DataSource.EVENT_REQUEST_FAIL,err)
   

         
  # Gets a cached url for that datasource                                                                                                           
  # Data from original url is imported to server who offers a cached version with option to filtering 
  getCachedURL: (config,forceImport="",cb)->
    url ="#{config.serverURL}/note/getCachedURL?noteid=#{config.noteid}&fonteIndex=#{@index}&forceImport=#{forceImport}"
    xhr = ajax.get(url,{type:'json'})
    xhr.done (res)=>
          @cachedURL = res.body.cachedUrl
          cb()
    xhr.fail (err)=>
        console.log(err)

  # callback function called on data loaded
  onDataLoaded: (data,fonte,config)->
    try
      for d, i in data
        @addItem(d,fonte.func_code)
      events.trigger(config.id,DataSource.EVENT_LOADED)
    catch e
      console.error(e.toString())
      events.trigger(config.id,DataSource.EVENT_LOAD_FAIL)
      return

   
module.exports = {DataSource:DataSource}
# vim: set ts=2 sw=2 sts=2 expandtab:

