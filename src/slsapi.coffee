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
  
   
SLSAPI.trigger = events.trigger
SLSAPI.on = events.on

SLSAPI.Notes = notes.Notes
SLSAPI.dataPool = dataPool
SLSAPI.ajax = ajax

if typeof process.browser!= 'undefined'
  window.SLSAPI = SLSAPI

module.exports = SLSAPI

# vim: set ts=2 sw=2 sts=2 expandtab:

