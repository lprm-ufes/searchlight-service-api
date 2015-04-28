ajax = require('./ajax.coffee')

class DataSource

  constructor: (url,func_code)->
    # process and validate the datasource
    @valid = true
    if url and typeof func_code is 'function'
      @url = url
      @func_code = func_code
    else
      if typeof func_code is 'string'
        try
          @func_code = string2function(func_code)
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
      geoItem = func_convert(i)
    catch e 
      console.error("Erro em Dados::addItem: #{e.message}",i)
      geoItem = null
          
    if geoItem
      # se o objeto nao tiver id um hash_id eh gerado.
      if not geoItem.id
       geoItem.hashid = "#{parseFloat(geoItem.latitude).toFixed(7)}#{parseFloat(geoItem.longitude).toFixed(7)}#{md5(JSON.stringify(geoItem))}" 
      else 
       if not geoItem.hashid
         geoItem.hashid = geoItem.id
       geoItem.id = undefined

      @notes.push(geoItem)
      if geoItem.id_parent
        @addChild(geoItem.id_parent,geoItem)

      cat = @_getCatOrCreate(geoItem)
      cat.push(geoItem)

  # taxonomize the notes
  addChild: (parentId,child) ->
    if not @notesChildren[parentId]
      @notesChildren[parentId] = [ ]
    @notesChildren[parentId].push(child)

  # load data to dataSource from the datasource.url
  loadData: (force=false,config) ->
    if config.usarCache and config.noteid
      @loadFromCache(config)
      return

    if @url.indexOf("docs.google.com/spreadsheet") > -1 
        @loadFromGoogle(config)
    else
      if @url.slice(0,4)=="http"
        if @url.slice(-4)==".csv"
          @loadFromCsv(config)
        else
          ajax.getJSONP(@url, (data)=>
              @onDataLoaded(data,@,config)
          )
      else
        ajax.getJSON(@url, (data) =>
          @onDataLoaded(data,@,config)
        )

  # callback function called on data loaded
  onDataLoaded: (data,fonte,config)->
    SLSAPI.trigger('slsapi:datasource:load',config.id)
    try
      for d, i in data
        @addItem(d,fonte.func_code)
    catch e
      console.error(e.toString())
      SLSAPI.trigger('slsapi:datasource:loadFail',config.id)
      return

  loadFromCache: (config)->
    ajax.getJSON("#{config.urlsls}/note/listaExternal?noteid=#{config.noteid}&fonteIndex=#{i}", (data)=>
              fonte2 ={ url:@url,func_code: (i)-> return i}           
              @onDataLoaded(data,fonte2)
    )

  loadFromGoogle: (config)->
    Tabletop.init {
      'key':@url,
      'callback':  (data)=>
          @onDataLoaded(data,@,config)
      ,
      'simpleSheet': true
    }

  loadFromCsv: ()->
    Papa.parse(@url, {
      header:true,
      download: true,
      error: ()-> alert("Erro ao baixar arquivo csv da fonte de dados:\n#{fonte.url}"),
      complete: (results, file) =>
        @onDataLoaded(results['data'],fonte,config)
      }
    )


   
module.exports = {DataSource:DataSource}
# vim: set ts=2 sw=2 sts=2 expandtab:

