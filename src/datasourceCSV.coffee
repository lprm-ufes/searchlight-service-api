if typeof process.browser == 'undefined'
  CLIENT_SIDE = false
  csvParse = require('babyparse')
else
  csvParse = Papa
  CLIENT_SIDE = true

DataSource = require('./datasource').DataSource
ajax = require './ajax'

class DataSourceCSV extends DataSource

  loadData: (config)->
    if CLIENT_SIDE
      csvParse.parse(@url, {
        header:true,
        download: true,
        error: ()=> alert("Erro ao baixar arquivo csv da fonte de dados:\n#{@url}"),
        complete: (results, file) =>

          console.log('teste')
          @onDataLoaded(results['data'],@,config)
        }
      )
    else
      xhr= ajax.get(@url)
      xhr.done( (body) =>
        parsed = csvParse.parse(body,{header:true})
        json = parsed.data
        @onDataLoaded(json,@,config)
      )
      xhr.fail((error)->
        console.log('error ao baixar CSV',error)
      )

   
module.exports = {DataSourceCSV:DataSourceCSV}
# vim: set ts=2 sw=2 sts=2 expandtab:

