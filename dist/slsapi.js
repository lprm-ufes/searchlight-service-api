(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var Config, utils;

utils = require('./utils.coffee');

Config = (function() {
  function Config(opcoes) {
    this.id = md5(JSON.stringify(opcoes));
    this.opcoes = new utils.Dicionario(opcoes);
    this.serverURL = this.opcoes.get('serverURL', 'http://sl.wancharle.com.br');
    this.createURL = this.opcoes.get('createURL', this.serverURL + "/note/create/");
    this.loginURL = this.opcoes.get('loginURL', this.serverURL + "/user/login/");
    this.logoutURL = this.opcoes.get('logoutURL', this.serverURL + "/user/logout/");
    this.notesURL = this.opcoes.get('notesURL', this.serverURL + "/note/");
    this.notebookURL = this.opcoes.get('notebookURL', this.serverURL + "/notebook/");
  }

  return Config;

})();

module.exports = {
  'Config': Config
};



},{"./utils.coffee":6}],2:[function(require,module,exports){
var Notebook;

Notebook = (function() {
  Notebook.instances = {};

  Notebook.getInstance = function(config) {
    return this.instances[config.id];
  };

  function Notebook(config) {
    Notebook.instances[config.id] = this;
    this.config = config;
  }

  Notebook.prototype.getByName = function(notebookName, callback, callbackFail) {
    var url;
    if (callbackFail == null) {
      callbackFail = null;
    }
    url = this.config.notebookURL + "?name=" + notebookName;
    return $.get(url, function(data) {
      console.log('ola');
      return callback(data);
    });
  };

  Notebook.prototype.getById = function(notebookId, callback, callbackFail) {
    var url;
    if (callbackFail == null) {
      callbackFail = null;
    }
    url = this.config.notebookURL + "?id=" + notebookId;
    return $.get(url, callback, callbackFail);
  };

  return Notebook;

})();

module.exports = {
  'Notebook': Notebook
};



},{}],3:[function(require,module,exports){
var Note, Notes;

Note = (function() {
  function Note(dados, notebook) {
    this.categoria = dados.categoria;
    this.comentarios = dados.comentarios;
    this.fotoURI = dados.fotoURI;
    this.lat = dados.lat ? dados.lat : '40.0';
    this.lng = dados.lng ? dados.lng : '-20.0';
    this.accuracy = dados.accuracy;
    this.user = dados.user_id;
    this.data_hora = dados.data_hora;
  }

  return Note;

})();

Notes = (function() {
  Notes.instances = {};

  Notes.getInstance = function(config) {
    return this.instances[config.id];
  };

  function Notes(config) {
    Notes.instances[config.id] = this;
    this.config = config;
  }

  Notes.prototype.getByUser = function(user_id, callback, callback_fail) {
    var xhr;
    xhr = $.get(this.config.notesURL + "?user=" + user_id);
    xhr.done(function(data) {
      return callback(data);
    });
    return xhr.fail(function() {
      return callback_fail();
    });
  };

  Notes.prototype.getByQuery = function(query, callback, callback_fail) {
    var xhr;
    xhr = $.get(this.config.notesURL + "?" + query);
    xhr.done(function(data) {
      return callback(data);
    });
    return xhr.fail(function() {
      return callback_fail();
    });
  };

  Notes.prototype.update = function(note_id, query, callback, callback_fail) {
    var xhr;
    xhr = $.get(this.config.notesURL + "update/" + note_id + "/?" + query);
    xhr.done(function(data) {
      return callback(data);
    });
    return xhr.fail(function() {
      return callback_fail();
    });
  };

  Notes.prototype["delete"] = function(note_id, callback) {
    return $.ajax({
      url: "" + this.config.notesURL + note_id,
      type: "DELETE",
      crossDomain: true,
      success: function(data) {
        return callback(data);
      }
    });
  };

  Notes.prototype.enviar = function(note, notebookId, callback_ok, callback_fail) {
    var ft, options, params;
    if (callback_ok == null) {
      callback_ok = (function() {});
    }
    if (callback_fail == null) {
      callback_fail = (function() {});
    }
    if (!notebookId) {
      console.error('NotebookId não foi informado!');
      return;
    }
    params = {};
    params.latitude = note.lat;
    params.longitude = note.lng;
    params.accuracy = note.accuracy;
    params.user = note.user;
    params.categoria = note.categoria;
    params.comentarios = note.comentarios;
    params.data_hora = note.data_hora;
    params.notebook = notebookId;
    $(document).trigger('slsapi.note:uploadStart');
    if (note.fotoURI) {
      options = new FileUploadOptions();
      options.params = params;
      options.fileKey = "foto";
      options.fileName = note.fotoURI.substr(note.fotoURI.lastIndexOf('/') + 1);
      options.mimeType = "image/jpeg";
      options.params.fotoURL = true;
      ft = new FileTransfer();
      return ft.upload(note.fotoURI, encodeURI(this.config.createURL), (function(_this) {
        return function(r) {
          $(document).trigger('slsapi.note:uploadFinish');
          return callback_ok(r);
        };
      })(this), (function(_this) {
        return function(error) {
          $(document).trigger('slsapi.note:uploadFail');
          return callback_fail(error);
        };
      })(this), options);
    } else {
      return $.post(this.config.createURL, params, function(json) {
        $(document).trigger('slsapi.note:uploadFinish');
        return callback_ok(json);
      }, 'json').fail(function(r) {
        $(document).trigger('slsapi.note:uploadFail');
        return callback_fail(error);
      });
    }
  };

  return Notes;

})();

module.exports = {
  'Notes': Notes,
  'Note': Note
};



},{}],4:[function(require,module,exports){
var Config, Notebook, Notes, SLSAPI, User;

Notes = require('./notes.coffee').Notes;

Notebook = require('./notebook.coffee').Notebook;

User = require('./user.coffee').User;

Config = require('./config.coffee').Config;

SLSAPI = (function() {
  function SLSAPI(opts) {
    $.ajaxSetup({
      crossDomain: true,
      xhrFields: {
        withCredentials: true
      }
    });
    this.config = new Config(opts);
    this.user = new User(this.config);
    this.notes = new Notes(this.config);
    this.notebook = new Notebook(this.config);
  }

  return SLSAPI;

})();

SLSAPI.Notes = Notes;

if (typeof window !== "undefined") {
  window.SLSAPI = SLSAPI;
}



},{"./config.coffee":1,"./notebook.coffee":2,"./notes.coffee":3,"./user.coffee":5}],5:[function(require,module,exports){
var User,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

User = (function() {
  User.instances = {};

  User.getInstance = function(config) {
    return this.instances[config.id];
  };

  function User(config1) {
    this.config = config1;
    this.login = bind(this.login, this);
    User.instances[this.config.id] = this;
    this.storage = window.localStorage;
    this.usuario = this.getUsuario();
  }

  User.prototype.isLogged = function() {
    var tempo_logado, usuario;
    usuario = this.getUsuario();
    if (usuario) {
      console.log(usuario);
      tempo_logado = ((new Date()).getTime() - this.logginTime) / 1000;
      if (tempo_logado > 24 * 3600) {
        return false;
      }
      return true;
    } else {
      return false;
    }
  };

  User.prototype.getUsuario = function() {
    this.usuario = this.storage.getItem('Usuario');
    this.user_id = this.storage.getItem('user_id');
    this.logginTime = this.storage.getItem('logginTime');
    return this.usuario;
  };

  User.prototype.setUsuario = function(usuario, json) {
    this.user_id = json.id;
    this.usuario = usuario;
    this.storage.setItem('Usuario', this.usuario);
    this.storage.setItem('user_id', this.user_id);
    return this.storage.setItem('logginTime', (new Date()).getTime());
  };

  User.prototype.logout = function(callback) {
    this.storage.removeItem('Usuario');
    this.usuario = null;
    this.user_id = null;
    return $.get(this.config.logoutURL, callback);
  };

  User.prototype.login = function(u, p) {
    var url;
    if (u && p) {
      url = this.config.loginURL;
      $(document).trigger('slsapi.user:loginStart');
      $.post(url, {
        username: u,
        password: p
      }, (function(_this) {
        return function(json) {
          if (json.error) {
            alert(json.error);
          } else {
            _this.setUsuario(u, json);
            $(document).trigger('slsapi.user:loginSuccess');
          }
          return $(document).trigger('slsapi.user:loginFinish');
        };
      })(this), "json").fail(function() {
        return $(document).trigger('slsapi.user:loginFail');
      });
    }
    return false;
  };

  return User;

})();

module.exports = {
  'User': User
};



},{}],6:[function(require,module,exports){
var Dicionario,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

Dicionario = (function() {
  function Dicionario(js_hash) {
    this.get = bind(this.get, this);
    this.keys = Object.keys(js_hash);
    this.data = js_hash;
  }

  Dicionario.prototype.get = function(key, value) {
    if (indexOf.call(this.keys, key) >= 0) {
      return this.data[key];
    } else {
      return value;
    }
  };

  return Dicionario;

})();

module.exports = {
  Dicionario: Dicionario
};



},{}]},{},[4]);
