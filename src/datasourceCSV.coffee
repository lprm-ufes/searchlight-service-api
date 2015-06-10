DataSource = require('./datasource').DataSource
ajax = require './ajax'

isRunningOnBrowser = require('./utils').isRunningOnBrowser
if not isRunningOnBrowser
  # Serverside definitions
  csvParse = require('babyparse')

  class DataSourceCSV extends DataSource
    loadData: (config)->
      xhr= ajax.get(@url,{buffer:true}) # buffer = true because is a download request (octet-stream response)
      xhr.done( (res) =>
        parsed = csvParse.parse(res.text,{header:true})
        json = parsed.data
        @onDataLoaded(json,@,config)
      )
      xhr.fail((error)->
        console.log('error ao baixar CSV',error)
      )
else
  # Clientside definitions
  if typeof Papa == 'undefined'
    csvParse = null
  else
    csvParse = Papa 

  class DataSourceCSV extends DataSource
    loadData: (config)->
      if csvParse
        csvParse.parse(@url, {
          header:true,
          download: true,
          error: ()=> alert("Erro ao baixar arquivo csv da fonte de dados:\n#{@url}"),
          complete: (results, file) =>
            @onDataLoaded(results['data'],@,config)
          }
        )
      else
        console.error('error: CSV format not suported in core-version. Download the full version bundle') 

   
module.exports = {DataSourceCSV:DataSourceCSV}
# vim: set ts=2 sw=2 sts=2 expandtab:

