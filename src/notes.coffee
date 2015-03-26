class Note
  constructor: (dados,notebook) ->
    @categoria = dados.categoria
    @comentarios = dados.comentarios
    @fotoURI = dados.fotoURI
    @lat =  if dados.lat then dados.lat else '40.0'
    @lng =  if dados.lng then dados.lng else '-20.0'
    @accuracy = dados.accuracy
    @user =  dados.user_id
    @data_hora = dados.data_hora


class Notes
  @instances = {} 

  @getInstance: (config) ->
    return @instances[config.id]

  constructor: (config) ->
    Notes.instances[config.id] = @
    @config = config 

  getByUser: (user_id,callback) ->
    $.get("#{@config.notesURL}?user=#{user_id}", (data)-> callback(data))
    
  delete: (note_id,callback)->
    $.ajax(
        url: "#{@config.notesURL}#{note_id}",
        type: "DELETE"
        crossDomain: true,
        success: (data)-> callback(data))

  enviar: (note,notebookId, callback_ok,callback_fail) ->
    if not notebookId
      console.error('NotebookId não foi informado!')
      return

    params = {}
    params.latitude = note.lat
    params.longitude = note.lng
    params.accuracy = note.accuracy
    params.user = note.user
    params.categoria = note.categoria
    params.comentarios = note.comentarios
    params.data_hora = note.data_hora
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
      ,'json').fail( () ->
        $(document).trigger('slsapi.note:uploadFail')

      )
 
module.exports = {'Notes':Notes,'Note':Note}

# vim: set ts=2 sw=2 sts=2 expandtab:

