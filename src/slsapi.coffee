
if typeof window != "undefined"
  CLIENT_SIDE = true
else
  CLIENT_SIDE = false

ajax = require('./ajax.coffee')
notes = require('./notes.coffee')
Notebook = require('./notebook.coffee').Notebook
User  = require('./user.coffee').User
Config  = require('./config.coffee').Config
DataSource  = require('./datasource.coffee').DataSource
DataPool = require('./datapool.coffee').DataPool


class SLSAPI
  @emitter: null
  
  constructor: (opts) ->
    @config = new Config(opts)
    @user = new User(@config)
    @notes = new notes.Notes(@config)
    @notebook = new Notebook(@config)
  
  @trigger:(event, param)->
    if CLIENT_SIDE
      $(document).trigger(event,param)
    else
      SLSAPI.emitter.emit(event,param)

  @on: (event,cb) ->
    if CLIENT_SIDE
      $(document).on(event,cb)
    else
      SLSAPI.emitter.on(event,cb)
    
    
SLSAPI.Notes = notes.Notes
SLSAPI.DataSource = DataSource
SLSAPI.DataPool = DataPool
SLSAPI.ajax = ajax

if CLIENT_SIDE
  window.SLSAPI = SLSAPI
else
  events = require('events')
  SLSAPI.emitter = new events.EventEmitter()

module.exports = SLSAPI

# vim: set ts=2 sw=2 sts=2 expandtab:

