DataSource = require('./datasource').DataSource
ajax = require './ajax'

isRunningOnBrowser = require('./utils').isRunningOnBrowser
if not isRunningOnBrowser
  # Serverside definitions
  csvParse = require('babyparse')

  class DataSourceCSV extends DataSource
    loadData: (config)->
      xhr= ajax.get(@url,true) # buffer = true because is a download request (octet-stream response)
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
  csvParse = Papa

  class DataSourceCSV extends DataSource
    loadData: (config)->
      csvParse.parse(@url, {
        header:true,
        download: true,
        error: ()=> alert("Erro ao baixar arquivo csv da fonte de dados:\n#{@url}"),
        complete: (results, file) =>
          @onDataLoaded(results['data'],@,config)
        }
      )

   
module.exports = {DataSourceCSV:DataSourceCSV}
# vim: set ts=2 sw=2 sts=2 expandtab:

