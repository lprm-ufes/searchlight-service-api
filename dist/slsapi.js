(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
// shim for using process in browser

var process = module.exports = {};
var queue = [];
var draining = false;
var currentQueue;
var queueIndex = -1;

function cleanUpNextTick() {
    draining = false;
    if (currentQueue.length) {
        queue = currentQueue.concat(queue);
    } else {
        queueIndex = -1;
    }
    if (queue.length) {
        drainQueue();
    }
}

function drainQueue() {
    if (draining) {
        return;
    }
    var timeout = setTimeout(cleanUpNextTick);
    draining = true;

    var len = queue.length;
    while(len) {
        currentQueue = queue;
        queue = [];
        while (++queueIndex < len) {
            currentQueue[queueIndex].run();
        }
        queueIndex = -1;
        len = queue.length;
    }
    currentQueue = null;
    draining = false;
    clearTimeout(timeout);
}

process.nextTick = function (fun) {
    var args = new Array(arguments.length - 1);
    if (arguments.length > 1) {
        for (var i = 1; i < arguments.length; i++) {
            args[i - 1] = arguments[i];
        }
    }
    queue.push(new Item(fun, args));
    if (!draining) {
        setTimeout(drainQueue, 0);
    }
};

// v8 likes predictible objects
function Item(fun, array) {
    this.fun = fun;
    this.array = array;
}
Item.prototype.run = function () {
    this.fun.apply(null, this.array);
};
process.title = 'browser';
process.browser = true;
process.env = {};
process.argv = [];
process.version = ''; // empty string to avoid regexp issues
process.versions = {};

function noop() {}

process.on = noop;
process.addListener = noop;
process.once = noop;
process.off = noop;
process.removeListener = noop;
process.removeAllListeners = noop;
process.emit = noop;

process.binding = function (name) {
    throw new Error('process.binding is not supported');
};

// TODO(shtylman)
process.cwd = function () { return '/' };
process.chdir = function (dir) {
    throw new Error('process.chdir is not supported');
};
process.umask = function() { return 0; };

},{}],2:[function(require,module,exports){
(function (process){
var Ajax, CLIENT_SIDE, del, get, getJSON, getJSONP, post, requestPromise;

if (typeof process.browser === 'undefined') {
  requestPromise = require('request-promise');
  requestPromise.defaults({
    jar: true
  });
  CLIENT_SIDE = false;
} else {
  CLIENT_SIDE = true;
}

Ajax = (function() {
  function Ajax() {
    this.xhr = null;
    if (CLIENT_SIDE) {
      $.ajaxSetup({
        crossDomain: true,
        xhrFields: {
          withCredentials: true
        }
      });
    }
  }

  Ajax.prototype.get = function(params) {
    if (CLIENT_SIDE) {
      this.xhr = $.get(params);
    } else {
      this.xhr = requestPromise.get(params);
    }
    return this;
  };

  Ajax.prototype.post = function(params) {
    if (CLIENT_SIDE) {
      this.xhr = $.post(params);
    } else {
      this.xhr = requestPromise.post(params);
    }
    return this;
  };

  Ajax.prototype["delete"] = function(params) {
    if (CLIENT_SIDE) {
      params.type = "DELETE";
      params.crossDomains = true;
      this.xhr = $.ajax(params);
    } else {
      this.xhr = requestPromise.del(params);
    }
    return this;
  };

  Ajax.prototype.done = function(cb) {
    if (CLIENT_SIDE) {
      return this.xhr.done(cb);
    } else {
      return this.xhr.then(cb);
    }
  };

  Ajax.prototype.fail = function(cb) {
    if (CLIENT_SIDE) {
      return this.xhr.fail(cb);
    } else {
      return this.xhr["catch"](cb);
    }
  };

  return Ajax;

})();

get = function(params) {
  return new Ajax().get(params);
};

post = function(params) {
  return new Ajax().post(params);
};

del = function(params) {
  return new Ajax()["delete"](params);
};

getJSONP = function(url, func) {
  var xhr;
  xhr = get({
    'url': url,
    'type': "POST",
    'dataType': 'jsonp'
  });
  xhr.done(func);
  return xhr.fail(function(e, ee) {
    if (ee === "error") {
      return console.log('Erro ao baixar dados JSONP da fonte de dados\n' + url);
    }
  });
};

getJSON = function(url, func) {
  var xhr;
  xhr = get({
    'url': url,
    'dataType': "json",
    'contentType': 'application/json',
    'mimeType': "textPlain"
  });
  xhr.done(func);
  return xhr.fail(function() {
    return console.log('Erro ao baixar dados JSONP da fonte de dados\n' + url);
  });
};

if (CLIENT_SIDE) {
  window.getJSONP = getJSONP;
  window.getJSON = getJSON;
}

module.exports = {
  get: get,
  post: post,
  del: del,
  getJSON: getJSON,
  getJSONP: getJSONP,
  Ajax: Ajax
};



}).call(this,require("/home/wancharle/searchlight-service-api/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js"))
},{"/home/wancharle/searchlight-service-api/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js":1,"request-promise":undefined}],3:[function(require,module,exports){
var Config, ajax, events, utils;

events = require('./events');

utils = require('./utils');

ajax = require('./ajax');

Config = (function() {
  function Config(opcoes) {
    var self, xhr;
    this.id = utils.md5(JSON.stringify(opcoes));
    self = this;
    this.parseOpcoes(opcoes);
    if (opcoes.urlConfServico) {
      xhr = ajax.get(opcoes.urlConfServico);
      xhr.done(function(opcoes) {
        self.parseOpcoes(opcoes);
        return events.trigger('slsapi.config:sucesso', self.id);
      });
      xhr.fail(function() {
        events.trigger('slsapi.config:fail', {
          id: self.id,
          error: 'Error: não foi possível carregar configuração da visualização'
        });
        return console.log('Error: não foi possível carregar configuração da visualização');
      });
    }
  }

  Config.prototype.parseOpcoes = function(opcoes, view) {
    this.opcoes = new utils.Dicionario(opcoes);
    this.serverURL = this.opcoes.get('serverURL', 'http://sl.wancharle.com.br');
    this.createURL = this.opcoes.get('createURL', this.serverURL + "/note/create/");
    this.loginURL = this.opcoes.get('loginURL', this.serverURL + "/user/login/");
    this.logoutURL = this.opcoes.get('logoutURL', this.serverURL + "/user/logout/");
    this.notesURL = this.opcoes.get('notesURL', this.serverURL + "/note/");
    this.notebookURL = this.opcoes.get('notebookURL', this.serverURL + "/notebook/");
    this.dataSources = this.opcoes.get('dataSources', []);
    if (!view) {
      return this.coletorNotebookId = this.opcoes.get('id', '');
    }
  };

  return Config;

})();

module.exports = {
  'Config': Config
};



},{"./ajax":2,"./events":7,"./utils":12}],4:[function(require,module,exports){
var DataPool, DataSource, DataSourceGoogle, createDataSource, events,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

events = require('./events');

DataSource = require('./datasource').DataSource;

DataSourceGoogle = require('./datasourceGoogle').DataSourceGoogle;

createDataSource = function(url, functionCode) {
  if (url.indexOf("docs.google.com/spreadsheet") > -1) {
    return new DataSourceGoogle(url, functionCode);
  } else {
    return new DataSource(url, functionCode);
  }
};

DataPool = (function() {
  DataPool.instances = {};

  DataPool.getInstance = function(config) {
    return this.instances[config.id];
  };

  function DataPool(config) {
    this.loadAllData = bind(this.loadAllData, this);
    var dataSources, index, j, len, s;
    DataPool.instances[config.id] = this;
    this.config = config;
    this.dataSources = [];
    dataSources = this.config.dataSources;
    for (index = j = 0, len = dataSources.length; j < len; index = ++j) {
      s = dataSources[index];
      this.addDataSource(s);
    }
    events.on('slsapi:datasource:load', (function(_this) {
      return function(id) {
        if (id === config.id) {
          return _this.onDataSourceLoaded();
        }
      };
    })(this));
  }

  DataPool.prototype.addDataSource = function(s) {
    var source;
    source = createDataSource(s.url, s.func_code);
    if (source.isValid()) {
      return this.dataSources.push(source);
    }
  };

  DataPool.prototype.removeDataSource = function(i) {
    return this.dataSources.splice(i, 1);
  };

  DataPool.prototype.getDataSources = function() {
    return this.dataSources;
  };

  DataPool.prototype.updateFonte = function(url, func_code, index) {
    return this.dataSources[index] = createDataSource(url, func_code);
  };

  DataPool.prototype.getDataSource = function(i) {
    return this.dataSources[i];
  };

  DataPool.prototype.loadAllData = function(callerId) {
    var i, j, len, obj, ref, results, source;
    obj = this;
    this.sourcesLoaded = 0;
    events.trigger("dados:carregando", callerId);
    ref = this.dataSources;
    results = [];
    for (i = j = 0, len = ref.length; j < len; i = ++j) {
      source = ref[i];
      results.push(source.loadData(this.config, false));
    }
    return results;
  };

  DataPool.prototype.toJSON = function() {
    var array, f, i, j, len, ref;
    array = [];
    ref = this.dataSources;
    for (i = j = 0, len = ref.length; j < len; i = ++j) {
      f = ref[i];
      f.func_code = f.func_code.toString();
      array.push(f);
    }
    return array;
  };

  DataPool.prototype.onDataSourceLoaded = function() {
    this.sourcesLoaded += 1;
    if (this.sourcesLoaded === this.dataSources.length) {
      return events.trigger('dados:carregados', this.config.id);
    }
  };

  return DataPool;

})();

module.exports = {
  DataPool: DataPool
};



},{"./datasource":5,"./datasourceGoogle":6,"./events":7}],5:[function(require,module,exports){
var DataSource, ajax, events, utils,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

events = require('./events');

ajax = require('./ajax');

utils = require('./utils');

DataSource = (function() {
  function DataSource(url, func_code) {
    this.addItem = bind(this.addItem, this);
    this._getCatOrCreate = bind(this._getCatOrCreate, this);
    var e;
    this.valid = true;
    if (url && typeof func_code === 'function') {
      this.url = url;
      this.func_code = func_code;
    } else {
      if (typeof func_code === 'string') {
        try {
          this.func_code = utils.string2function(func_code);
          this.url = url;
        } catch (_error) {
          e = _error;
          console.error(e, 'Error ao tentar criar funcao de conversao apartir de texto');
          this.valid = false;
        }
      } else {
        console.error("Error de configuração de fonte:", {
          url: url,
          func_code: func_code
        });
        this.valid = false;
      }
    }
    this.notes = [];
    this.notesChildren = {};
    this.categories = {};
    this.categories_id = {};
  }

  DataSource.prototype.isValid = function() {
    return this.valid;
  };

  DataSource.prototype._getCatOrCreate = function(i) {
    var cat;
    cat = this.categories[i.cat];
    if (cat) {
      return cat;
    } else {
      this.categories[i.cat] = [];
      this.categories_id[i.cat] = i.cat_id;
      return this.categories[i.cat];
    }
  };

  DataSource.prototype.addItem = function(i, func_convert) {
    var cat, e, geoItem;
    try {
      geoItem = func_convert(i);
    } catch (_error) {
      e = _error;
      console.error("Erro em Dados::addItem: " + e.message, i);
      geoItem = null;
    }
    if (geoItem) {
      if (!geoItem.id) {
        geoItem.hashid = "" + (parseFloat(geoItem.latitude).toFixed(7)) + (parseFloat(geoItem.longitude).toFixed(7)) + (utils.md5(JSON.stringify(geoItem)));
      } else {
        if (!geoItem.hashid) {
          geoItem.hashid = geoItem.id;
        }
        geoItem.id = void 0;
      }
      this.notes.push(geoItem);
      if (geoItem.id_parent) {
        this.addChild(geoItem.id_parent, geoItem);
      }
      cat = this._getCatOrCreate(geoItem);
      return cat.push(geoItem);
    }
  };

  DataSource.prototype.addChild = function(parentId, child) {
    if (!this.notesChildren[parentId]) {
      this.notesChildren[parentId] = [];
    }
    return this.notesChildren[parentId].push(child);
  };

  DataSource.prototype.loadData = function(config, force) {
    if (force == null) {
      force = false;
    }
    if (config.usarCache && config.noteid) {
      this.loadFromCache(config);
      return;
    }
    if (this.url.indexOf("docs.google.com/spreadsheet") > -1) {
      return this.loadFromGoogle(config);
    } else {
      if (this.url.slice(0, 4) === "http") {
        if (this.url.slice(-4) === ".csv") {
          return this.loadFromCsv(config);
        } else {
          return ajax.getJSONP(this.url, (function(_this) {
            return function(data) {
              return _this.onDataLoaded(data, _this, config);
            };
          })(this));
        }
      } else {
        return ajax.getJSON(this.url, (function(_this) {
          return function(data) {
            return _this.onDataLoaded(data, _this, config);
          };
        })(this));
      }
    }
  };

  DataSource.prototype.onDataLoaded = function(data, fonte, config) {
    var d, e, i, j, len;
    try {
      for (i = j = 0, len = data.length; j < len; i = ++j) {
        d = data[i];
        this.addItem(d, fonte.func_code);
      }
      return events.trigger('slsapi:datasource:load', config.id);
    } catch (_error) {
      e = _error;
      console.error(e.toString());
      events.trigger('slsapi:datasource:loadFail', config.id);
    }
  };

  DataSource.prototype.loadFromCache = function(config) {
    return ajax.getJSON(config.urlsls + "/note/listaExternal?noteid=" + config.noteid + "&fonteIndex=" + i, (function(_this) {
      return function(data) {
        var fonte2;
        fonte2 = {
          url: _this.url,
          func_code: function(i) {
            return i;
          }
        };
        return _this.onDataLoaded(data, fonte2);
      };
    })(this));
  };

  DataSource.prototype.loadFromGoogle = function(config) {
    return Tabletop.init({
      'key': this.url,
      'callback': (function(_this) {
        return function(data) {
          return _this.onDataLoaded(data, _this, config);
        };
      })(this),
      'simpleSheet': true
    });
  };

  DataSource.prototype.loadFromCsv = function() {
    return Papa.parse(this.url, {
      header: true,
      download: true,
      error: function() {
        return alert("Erro ao baixar arquivo csv da fonte de dados:\n" + fonte.url);
      },
      complete: (function(_this) {
        return function(results, file) {
          return _this.onDataLoaded(results['data'], fonte, config);
        };
      })(this)
    });
  };

  return DataSource;

})();

module.exports = {
  DataSource: DataSource
};



},{"./ajax":2,"./events":7,"./utils":12}],6:[function(require,module,exports){
(function (process){
var CLIENT_SIDE, DataSource, DataSourceGoogle, TABLETOP,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

if (typeof process.browser === 'undefined') {
  CLIENT_SIDE = false;
  TABLETOP = require('tabletop');
} else {
  TABLETOP = Tabletop;
  CLIENT_SIDE = true;
}

DataSource = require('./datasource').DataSource;

DataSourceGoogle = (function(superClass) {
  extend(DataSourceGoogle, superClass);

  function DataSourceGoogle() {
    return DataSourceGoogle.__super__.constructor.apply(this, arguments);
  }

  DataSourceGoogle.prototype.loadData = function(config) {
    return TABLETOP.init({
      'key': this.url,
      'callback': (function(_this) {
        return function(data, tabletop) {
          return _this.onDataLoaded(data, _this, config);
        };
      })(this),
      'simpleSheet': true
    });
  };

  return DataSourceGoogle;

})(DataSource);

module.exports = {
  DataSourceGoogle: DataSourceGoogle
};



}).call(this,require("/home/wancharle/searchlight-service-api/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js"))
},{"./datasource":5,"/home/wancharle/searchlight-service-api/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js":1,"tabletop":undefined}],7:[function(require,module,exports){
(function (process){
var CLIENT_SIDE, bind, emitter, events, trigger;

emitter = null;

if (typeof process.browser === 'undefined') {
  CLIENT_SIDE = false;
  events = require('events');
  emitter = new events.EventEmitter();
} else {
  CLIENT_SIDE = true;
}

trigger = function(event, param) {
  if (CLIENT_SIDE) {
    return $(document).trigger(event, param);
  } else {
    return emitter.emit(event, param);
  }
};

bind = function(event, cb) {
  if (CLIENT_SIDE) {
    return $(document).on(event, function(caller, params) {
      return cb(params);
    });
  } else {
    return emitter.on(event, cb);
  }
};

module.exports = {
  trigger: trigger,
  on: bind
};



}).call(this,require("/home/wancharle/searchlight-service-api/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js"))
},{"/home/wancharle/searchlight-service-api/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js":1,"events":undefined}],8:[function(require,module,exports){
var Notebook, ajax;

ajax = require('./ajax');

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
    var url, xhr;
    if (callbackFail == null) {
      callbackFail = null;
    }
    url = this.config.notebookURL + "?name=" + notebookName;
    xhr = ajax.get(url);
    return xhr.done(function(data) {
      return callback(data);
    });
  };

  Notebook.prototype.getById = function(notebookId, callback, callbackFail) {
    var url, xhr;
    if (callbackFail == null) {
      callbackFail = null;
    }
    url = this.config.notebookURL + "?id=" + notebookId;
    xhr = ajax.get(url);
    xhr.done(callback);
    return xhr.fail(callbackFail);
  };

  return Notebook;

})();

module.exports = {
  'Notebook': Notebook
};



},{"./ajax":2}],9:[function(require,module,exports){
var Notes, ajax;

ajax = require('./ajax');

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
    xhr = ajax.get(this.config.notesURL + "?user=" + user_id);
    xhr.done(function(data) {
      return callback(data);
    });
    return xhr.fail(function() {
      return callback_fail();
    });
  };

  Notes.prototype.getByQuery = function(query, callback, callback_fail) {
    var xhr;
    xhr = ajax.get(this.config.notesURL + "?" + query);
    xhr.done(function(data) {
      return callback(data);
    });
    return xhr.fail(function() {
      return callback_fail();
    });
  };

  Notes.prototype.update = function(note_id, queryparams, callback, callback_fail) {
    var xhr;
    xhr = ajax.post(this.config.notesURL + "update/" + note_id + "/", queryparams);
    xhr.done(function(data) {
      return callback(data);
    });
    return xhr.fail(function() {
      return callback_fail();
    });
  };

  Notes.prototype["delete"] = function(note_id, callback) {
    var xhr;
    xhr = ajax.del({
      url: "" + this.config.notesURL + note_id
    });
    return xhr.done(function(data) {
      return callback(data);
    });
  };

  Notes.prototype.enviar = function(note, notebookId, callback_ok, callback_fail) {
    var ft, options, params;
    if (notebookId == null) {
      notebookId = null;
    }
    if (callback_ok == null) {
      callback_ok = (function() {});
    }
    if (callback_fail == null) {
      callback_fail = (function() {});
    }
    if (!notebookId) {
      if (!this.config.coletorNotebookId) {
        console.error('NotebookId não foi informado!');
        return;
      } else {
        notebookId = this.config.coletorNotebookId;
      }
    }
    params = note;
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
      }, 'json').fail(function(error) {
        $(document).trigger('slsapi.note:uploadFail');
        return callback_fail(error);
      });
    }
  };

  return Notes;

})();

module.exports = {
  'Notes': Notes
};



},{"./ajax":2}],10:[function(require,module,exports){
(function (process){
var Config, Notebook, SLSAPI, User, ajax, dataPool, events, notes;

events = require('./events');

ajax = require('./ajax');

notes = require('./notes');

Notebook = require('./notebook').Notebook;

User = require('./user').User;

Config = require('./config').Config;

dataPool = require('./datapool');

SLSAPI = (function() {
  function SLSAPI(opts) {
    this.config = new Config(opts);
    this.user = new User(this.config);
    this.notes = new notes.Notes(this.config);
    this.notebook = new Notebook(this.config);
  }

  return SLSAPI;

})();

SLSAPI.trigger = events.trigger;

SLSAPI.on = events.on;

SLSAPI.Notes = notes.Notes;

SLSAPI.dataPool = dataPool;

SLSAPI.ajax = ajax;

if (typeof process.browser !== 'undefined') {
  window.SLSAPI = SLSAPI;
}

module.exports = SLSAPI;



}).call(this,require("/home/wancharle/searchlight-service-api/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js"))
},{"./ajax":2,"./config":3,"./datapool":4,"./events":7,"./notebook":8,"./notes":9,"./user":11,"/home/wancharle/searchlight-service-api/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js":1}],11:[function(require,module,exports){
(function (process){
var CLIENT_SIDE, LocalStorage, User, localStorage, md5,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

if (typeof process.browser === 'undefined') {
  md5 = require('blueimp-md5').md5;
  LocalStorage = require('node-localstorage').LocalStorage;
  localStorage = new LocalStorage('./scratch');
  CLIENT_SIDE = false;
} else {
  CLIENT_SIDE = true;
  localStorage = window.localStorage;
  md5 = window.md5;
}

User = (function() {
  User.instances = {};

  User.getInstance = function(config) {
    return this.instances[config.id];
  };

  function User(config1) {
    this.config = config1;
    this.login = bind(this.login, this);
    User.instances[this.config.id] = this;
    this.storage = localStorage;
    this.usuario = this.getUsuario();
  }

  User.prototype.isLogged = function() {
    var tempo_logado, usuario;
    usuario = this.getUsuario();
    if (usuario) {
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



}).call(this,require("/home/wancharle/searchlight-service-api/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js"))
},{"/home/wancharle/searchlight-service-api/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js":1,"blueimp-md5":undefined,"node-localstorage":undefined}],12:[function(require,module,exports){
(function (process){
var CLIENT_SIDE, Dicionario, getURLParameter, md5, parseFloatPTBR, string2function,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

if (typeof process.browser === 'undefined') {
  md5 = require('blueimp-md5').md5;
  CLIENT_SIDE = false;
} else {
  CLIENT_SIDE = true;
  md5 = window.md5;
}

Dicionario = (function() {
  function Dicionario(js_hash) {
    this.get = bind(this.get, this);
    if (typeof js_hash === 'string') {
      js_hash = JSON.parse(js_hash);
    }
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

getURLParameter = function(name) {
  return $(document).getUrlParam(name);
};

string2function = function(func_code) {
  var m, nome, re;
  re = /.*function *(\w*) *\( *(\w*) *\) *\{/mg;
  if ((m = re.exec(func_code)) !== null) {
    if (m.index === re.lastIndex) {
      re.lastIndex++;
    }
    nome = m[1] || 'slsAnonymousFunction';
    if (CLIENT_SIDE) {
      return eval("window['" + nome + "']=" + func_code);
    } else {
      return eval("exports['" + nome + "']=" + func_code);
    }
  } else {
    return null;
  }
};

parseFloatPTBR = function(str) {
  var itens;
  itens = String(str).match(/^(-*\d+)([\,\.]*)(\d+)?$/);
  if (itens[2]) {
    return parseFloat(itens[1] + "." + itens[3]);
  } else {
    return parseFloat(itens[1]);
  }
};

if (CLIENT_SIDE) {
  window.parseFloatPTBR = parseFloatPTBR;
  window.string2function = string2function;
  window.getURLParameter = getURLParameter;
}

module.exports = {
  Dicionario: Dicionario,
  parseFloatPTBR: parseFloatPTBR,
  string2function: string2function,
  getURLParameter: getURLParameter,
  md5: md5
};



}).call(this,require("/home/wancharle/searchlight-service-api/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js"))
},{"/home/wancharle/searchlight-service-api/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js":1,"blueimp-md5":undefined}]},{},[10]);
