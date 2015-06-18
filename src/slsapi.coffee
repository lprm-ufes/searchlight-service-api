isRunningOnBrowser = require('./utils').isRunningOnBrowser
utils = require('./utils')
events = require('./events')
ajax = require('./ajax')
notes = require('./notes')
Notebook = require('./notebook').Notebook
User  = require('./user').User
Config  = require('./config').Config
Mashup  = require('./mashup').Mashup
dataPool = require('./datapool')
DataSource = require('./datasource').DataSource

class SLSAPI
  
  constructor: (opts) ->
    @config = new Config(opts)
    @user = new User(@config)
    @notes = new notes.Notes(@config)
    @notebook = new Notebook(@config)
    @mashup = new Mashup(@config)
 
  # shortcuts which abstract the use of events
  trigger: (event,params)->
    events.trigger(@config.id,event,params)

  on: (event,params)->
    events.on(@config.id,event,params)

  off: (event,params)->
    events.off(@config.id,event,params)


   
SLSAPI.Config = Config
SLSAPI.Notes = notes.Notes
SLSAPI.User = User
SLSAPI.dataPool = dataPool
SLSAPI.DataSource = DataSource
SLSAPI.ajax = ajax
SLSAPI.utils = utils
SLSAPI.events = events


if isRunningOnBrowser
  window.SLSAPI = SLSAPI

module.exports = SLSAPI

# vim: set ts=2 sw=2 sts=2 expandtab:

