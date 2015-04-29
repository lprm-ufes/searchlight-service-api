ajax = require './ajax'

class Notes
  @instances = {} 

  @getInstance: (config) ->
    return @instances[config.id]

  constructor: (config) ->
    Notes.instances[config.id] = @
    @config = config 

  getByUser: (user_id,callback, callback_fail) ->
    xhr = ajax.get("#{@config.notesURL}?user=#{user_id}")
    xhr.done( (data)-> callback(data))
    xhr.fail( () -> callback_fail())

  getByQuery: (query,callback, callback_fail) ->
    xhr = ajax.get("#{@config.notesURL}?#{query}")
    xhr.done( (data)-> callback(data))
    xhr.fail( () -> callback_fail())

  update: (note_id,queryparams,callback,callback_fail)->
    xhr = ajax.post("#{@config.notesURL}update/#{note_id}/",queryparams)
    xhr.done( (data)-> callback(data))
    xhr.fail( () -> callback_fail())

  delete: (note_id,callback)->
    xhr = ajax.del(url: "#{@config.notesURL}#{note_id}")
    xhr.done((data)-> callback(data))

  enviar: (note,notebookId=null, callback_ok=(()->),callback_fail=(()->)) ->
    if not notebookId
      if not @config.coletorNotebookId
        console.error('NotebookId não foi informado!')
        return
      else
        notebookId = @config.coletorNotebookId


    params = note
    params.notebook = notebookId

    $(document).trigger('slsapi.note:uploadStart')
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
            $(document).trigger('slsapi.note:uploadFinish')
            callback_ok(r)
          ,(error) =>
            $(document).trigger('slsapi.note:uploadFail')
            callback_fail(error)
          , options)
    else
      $.post(@config.createURL, params, (json) ->
        $(document).trigger('slsapi.note:uploadFinish')
        callback_ok(json)
      ,'json').fail( (error) ->
        $(document).trigger('slsapi.note:uploadFail')
        callback_fail(error) 
      )
 
module.exports = {'Notes':Notes}

# vim: set ts=2 sw=2 sts=2 expandtab:

