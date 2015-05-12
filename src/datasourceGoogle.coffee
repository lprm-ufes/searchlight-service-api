
isRunningOnBrowser = require('./utils').isRunningOnBrowser
if not isRunningOnBrowser
  TABLETOP = require('tabletop')
else
  TABLETOP = Tabletop

DataSource = require('./datasource').DataSource

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

