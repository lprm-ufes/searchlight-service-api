notes = require('./notes.coffee')
Notebook = require('./notebook.coffee').Notebook
User  = require('./user.coffee').User
Config  = require('./config.coffee').Config

class SLSAPI
  constructor: (opts) ->
    $.ajaxSetup({
        crossDomain: true,
        xhrFields: {
          withCredentials: true
        },
    })

    @config = new Config(opts)
    @user = new User(@config)
    @notes = new notes.Notes(@config)
    @notebook = new Notebook(@config)
    

SLSAPI.Notes = notes.Notes
SLSLAP.Note = notes.Note
if typeof window != "undefined"
  window.SLSAPI = SLSAPI

# vim: set ts=2 sw=2 sts=2 expandtab:

