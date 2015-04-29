if typeof process.browser == 'undefined' 
  CLIENT_SIDE = false
  TABLETOP = require('tabletop')
else
  TABLETOP = Tabletop
  CLIENT_SIDE = true

DataSource = require('./datasource.coffee').DataSource

class DataSourceGoogle extends DataSource

  loadData: (config) ->
    TABLETOP.init {
      'key':@url,
      'callback':  (data,tabletop) =>
          @onDataLoaded(data,@,config)
      ,
      'simpleSheet': true
    }

   
module.exports = {DataSourceGoogle:DataSourceGoogle}
# vim: set ts=2 sw=2 sts=2 expandtab:

