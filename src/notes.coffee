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

  constructor: (config) ->
    Notes.instances[config.id] = @
    @config = config 

  getByUser: (user_id,callback, callback_fail) ->
    xhr = ajax.get("#{@config.notesURL}?user=#{user_id}")
    xhr.done( (res)-> callback(res.body))
    xhr.fail( (err) -> callback_fail(err))

  getByQuery: (query,callback, callback_fail) ->
    xhr = ajax.get("#{@config.notesURL}?#{query}")
    xhr.done( (res)-> callback(res.body))
    xhr.fail( (err) -> callback_fail(err))

  update: (note_id,queryparams,callback,callback_fail)->
    xhr = ajax.post({url:"#{@config.notesURL}update/#{note_id}/",data:queryparams})
    xhr.done( (res)-> callback(res.body))
    xhr.fail( (err) -> callback_fail(err))

  delete: (note_id,callback)->
    url ="#{@config.notesURL}#{note_id}"
    xhr = ajax.del url
    if callback
      xhr.done((data)-> callback(data))
    else
      xhr.done((data)=>events.trigger(@config.id,Notes.EVENT_DEL_NOTE_SUCCESS,data))

    xhr.fail((err)=>events.trigger(@config.id,Notes.EVENT_DEL_NOTE_FAIL,err))

  enviar: (note,notebookId=null, callback_ok=(()->),callback_fail=(()->)) ->
    if not notebookId
      if not @config.coletorNotebookId
        console.error('NotebookId não foi informado!')
        return
      else
        notebookId = @config.coletorNotebookId


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
          encodeURI(@config.createURL),
          (r) =>
            events.trigger(@config.id,Notes.EVENT_ADD_NOTE_FINISH)
            callback_ok(r)
          ,(error) =>
            events.trigger(@config.id, Notes.EVENT_ADD_NOTE_FAIL)
            callback_fail(error)
          , options)
    else
      xhr = ajax.post({url:@config.createURL, data:params})
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

