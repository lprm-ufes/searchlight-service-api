ajax = require './ajax'
events = require './events'

class Notes
  @EVENT_ADD_NOTE_START = 'note:uploadStart.slsapi'
  @EVENT_ADD_NOTE_FINISH = 'note:uploadFinish.slsapi'
  @EVENT_ADD_NOTE_FAIL = 'note:uploadFail.slsapi'
  @EVENT_DEL_NOTE_FAIL = 'note:deleteFail.slsapi'
  @EVENT_DEL_NOTE_SUCCESS = 'note:deleteSUCCESS.slsapi'

  @instances = {} 

  @getInstance: (config) ->
    return @instances[config.id]

  constructor: (@config) ->
    Notes.instances[@config.id] = @
    @config.register(@)

  parseOpcoes: (@opcoes)->
    @createURL = @opcoes.get 'notesCreateURL', @createURL or "#{@config.serverURL}/note/create/"
    @readURL = @opcoes.get 'notesReadURL', @readURL or "#{@config.serverURL}/note/"
    @updateURL = @opcoes.get 'notesUpdateURL', @updateURL or "#{@config.serverURL}/note/update/"

    @storageNotebook = @opcoes.get 'storageNotebook', ''

  toJSON: ->
    {
      notesCreateURL:@createURL
      notesReadURL: @readURL
      notesUpdateURL: @updateURL
      storageNotebook: @storageNotebook
    }

  getByUser: (user_id,callback, callback_fail) ->
    xhr = ajax.get("#{@readURL}?user=#{user_id}")
    xhr.done( (res)-> callback(res.body))
    xhr.fail( (err) -> callback_fail(err))

  getByQuery: (query,callback, callback_fail) ->
    xhr = ajax.get("#{@readURL}?#{query}")
    xhr.done( (res)-> callback(res.body))
    xhr.fail( (err) -> callback_fail(err))

  update: (note_id,queryparams,callback,callback_fail)->
    xhr = ajax.post({url:"#{@updateURL}#{note_id}/",data:queryparams})
    xhr.done( (res)-> callback(res.body))
    xhr.fail( (err) -> callback_fail(err))

  delete: (note_id,callback)->
    url ="#{@readURL}#{note_id}"
    xhr = ajax.del url
    if callback
      xhr.done((data)-> callback(data))
    else
      xhr.done((data)=>events.trigger(@config.id,Notes.EVENT_DEL_NOTE_SUCCESS,data))

    xhr.fail((err)=>events.trigger(@config.id,Notes.EVENT_DEL_NOTE_FAIL,err))

  enviar: (note,notebookId=null, callback_ok=(()->),callback_fail=(()->)) ->
    if not notebookId
      if not @storageNotebook
        console.error('NotebookId não foi informado!')
        return
      else
        notebookId = @storageNotebook.id


    params = note
    params.notebook = notebookId

    events.trigger(@config.id,Notes.EVENT_ADD_NOTE_START)
    if note.fotoURI
        options = new FileUploadOptions()
        options.params = params
        options.fileKey = "foto"
        options.fileName = note.fotoURI.substr(note.fotoURI.lastIndexOf('/') + 1)
        options.mimeType = "image/jpeg"
        
        options.params.fotoURL = true
        ft = new FileTransfer()
        ft.upload(
          note.fotoURI,
          encodeURI(@createURL),
          (r) =>
            events.trigger(@config.id,Notes.EVENT_ADD_NOTE_FINISH)
            callback_ok(r)
          ,(error) =>
            events.trigger(@config.id, Notes.EVENT_ADD_NOTE_FAIL)
            callback_fail(error)
          , options)
    else
      xhr = ajax.post({url:@createURL, data:params})
      xhr.done((res) =>
        events.trigger(@config.id,Notes.EVENT_ADD_NOTE_FINISH,res.body)
        callback_ok(res.body)
      )
      xhr.fail( (error) =>
        events.trigger(@config.id,Notes.EVENT_ADD_NOTE_FAIL,error)
        callback_fail(error)
      )
 
module.exports = {'Notes':Notes}

# vim: set ts=2 sw=2 sts=2 expandtab:

