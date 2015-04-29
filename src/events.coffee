
emitter= null
if typeof process.browser == 'undefined' 
  CLIENT_SIDE = false
  events = require('events')
  emitter = new events.EventEmitter()
else
  CLIENT_SIDE = true


trigger= (event, param)->
    if CLIENT_SIDE
      $(document).trigger(event,param)
    else
      emitter.emit(event,param)


bind = (event,cb) ->
    if CLIENT_SIDE
      $(document).on(event, (caller,params) -> cb(params))
    else
      emitter.on(event,cb)

module.exports = {trigger:trigger, on:bind}

# vim: set ts=2 sw=2 sts=2 expandtab:

