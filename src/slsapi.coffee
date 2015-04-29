events = require('./events.coffee')
ajax = require('./ajax.coffee')
notes = require('./notes.coffee')
Notebook = require('./notebook.coffee').Notebook
User  = require('./user.coffee').User
Config  = require('./config.coffee').Config
dataPool = require('./datapool.coffee')

class SLSAPI
  
  constructor: (opts) ->
    @config = new Config(opts)
    @user = new User(@config)
    @notes = new notes.Notes(@config)
    @notebook = new Notebook(@config)
  
   
SLSAPI.trigger = events.trigger
SLSAPI.on = events.on

SLSAPI.Notes = notes.Notes
SLSAPI.dataPool = dataPool
SLSAPI.ajax = ajax

if typeof process.browser!= 'undefined'
  window.SLSAPI = SLSAPI

module.exports = SLSAPI

# vim: set ts=2 sw=2 sts=2 expandtab:

