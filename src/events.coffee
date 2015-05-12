emitter= null

isRunningOnBrowser = require('./utils').isRunningOnBrowser
if not isRunningOnBrowser
  # define serveside functions
  events = require('events')

  emitters = {}
  
  select = (id) ->
    if not(id of emitters)
      emitters[id] = new events.EventEmitter()
    return emitters[id]

  trigger = (id,event, param) ->
    select(id).emit(event,param)

  bind = (id,event,cb) ->
    select(id).once(event,cb)

  unbind = (id,event,cb) ->
    

else
  # define clientside functions
  select = (id)->
    target = $("#slEvent#{id}")
    if target.length <= 0
      # create a target element to serve as emitter object
      target = $("<div id='slEvent#{id}'> </div>")
      $("body").append(target)
    return target

  trigger= (id,event, param)->
    select(id).trigger(event,param)

  bind = (id,event,cb) ->
    f = (caller,params) -> cb(params)
    select(id).on(event,f)

  unbind = (id,event,cb) ->
    select(id).off(event)


module.exports = {trigger:trigger, on:bind, off:unbind}

# vim: set ts=2 sw=2 sts=2 expandtab:

