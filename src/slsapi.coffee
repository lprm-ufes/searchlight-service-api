notes  = require './notes.coffee'
user  = require './user.coffee'
config  = require './config.coffee'

class window.SLSAPI
  constructor: (opts) ->
    $.ajaxSetup({
        crossDomain: true,
        xhrFields: {
          withCredentials: true
        },
    })

    @config = new config.Config(opts)
    @user = new user.User(@config)
    @notes = new notes.Notes(@config)
    

SLSAPI.notes = notes
# vim: set ts=2 sw=2 sts=2 expandtab:

