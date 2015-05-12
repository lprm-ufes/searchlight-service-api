isRunningOnBrowser = require('./utils').isRunningOnBrowser
events = require('./events')
ajax = require('./ajax')
notes = require('./notes')
Notebook = require('./notebook').Notebook
User  = require('./user').User
Config  = require('./config').Config
dataPool = require('./datapool')

class SLSAPI
  
  constructor: (opts) ->
    @config = new Config(opts)
    @user = new User(@config)
    @notes = new notes.Notes(@config)
    @notebook = new Notebook(@config)
 
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
SLSAPI.ajax = ajax


if isRunningOnBrowser
  window.SLSAPI = SLSAPI

module.exports = SLSAPI

# vim: set ts=2 sw=2 sts=2 expandtab:

