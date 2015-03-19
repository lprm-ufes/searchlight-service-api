(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var Config, utils;

utils = require('./utils.coffee');

Config = (function() {
  function Config(opcoes) {
    this.opcoes = new utils.Dicionario(opcoes);
    this.serverURL = this.opcoes.get('serverURL', 'http://sl.wancharle.com.br');
    this.createURL = this.opcoes.get('createURL', this.serverURL + "/note/create/");
    this.loginURL = this.opcoes.get('loginURL', this.serverURL + "/user/login/");
    this.logoutURL = this.opcoes.get('logoutURL', this.serverURL + "/user/logout/");
    this.notesURL = this.opcoes.get('notesURL', this.serverURL + "/note/");
  }

  return Config;

})();

module.exports = {
  'Config': Config
};



},{"./utils.coffee":5}],2:[function(require,module,exports){
var Note, Notes;

Note = (function() {
  function Note(dados) {
    this.categoria = dados.categoria;
    this.comentarios = dados.comentarios;
    this.fotoURI = dados.fotoURI;
    this.lat = dados.lat ? dados.lat : '40.0';
    this.lng = dados.lng ? dados.lng : '-20.0';
    this.accuracy = dados.accuracy;
    this.user = dados.user_id ? dados.user_id : 1;
    this.data_hora = dados.data_hora;
  }

  return Note;

})();

Notes = (function() {
  function Notes(config, dados) {
    this.config = config;
  }

  Notes.prototype.getByUser = function(user_id, callback) {
    return $.get(this.config.notesURL + "?user=" + user_id, function(data) {
      return callback(data);
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

  Notes.prototype.enviar = function(note, callback_ok, callback_fail) {
    var ft, options, params;
    params = {};
    params.latitude = note.lat;
    params.longitude = note.lng;
    params.accuracy = note.accuracy;
    params.user = note.user;
    params.categoria = note.categoria;
    params.comentarios = note.comentarios;
    params.data_hora = note.data_hora;
    console.log(params);
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
        return $(document).trigger('slsapi.note:uploadFinish');
      }, 'json').fail(function() {
        return $(document).trigger('slsapi.note:uploadFail');
      });
    }
  };

  return Notes;

})();

module.exports = {
  'Notes': Notes,
  'Note': Note
};



},{}],3:[function(require,module,exports){
var config, notes, user;

notes = require('./notes.coffee');

user = require('./user.coffee');

config = require('./config.coffee');

window.SLSAPI = (function() {
  function SLSAPI(opts) {
    $.ajaxSetup({
      crossDomain: true,
      xhrFields: {
        withCredentials: true
      }
    });
    this.config = new config.Config(opts);
    this.user = new user.User(this.config);
    this.notes = new notes.Notes(this.config);
  }

  return SLSAPI;

})();

SLSAPI.notes = notes;



},{"./config.coffee":1,"./notes.coffee":2,"./user.coffee":4}],4:[function(require,module,exports){
var User, notes,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

notes = require('./notes.coffee');

User = (function() {
  function User(config) {
    this.config = config;
    this.login = bind(this.login, this);
    this.storage = window.localStorage;
    this.usuario = this.getUsuario();
    this.notes = new notes.Notes(this.config);
  }

  User.prototype.isLogged = function() {
    return this.getUsuario();
  };

  User.prototype.getUsuario = function() {
    this.usuario = this.storage.getItem('Usuario');
    this.user_id = this.storage.getItem('user_id');
    return this.usuario;
  };

  User.prototype.setUsuario = function(usuario, json) {
    this.user_id = json.id;
    this.usuario = usuario;
    this.storage.setItem('Usuario', this.usuario);
    return this.storage.setItem('user_id', this.user_id);
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

  User.prototype.getNotes = function(callback) {
    return this.notes.getByUser(this.user_id, function(data) {
      return callback(data);
    });
  };

  return User;

})();

module.exports = {
  'User': User
};



},{"./notes.coffee":2}],5:[function(require,module,exports){
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



},{}]},{},[3]);
