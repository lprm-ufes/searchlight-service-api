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
var Ajax, del, get, getJSON, getJSONP, isRunningOnBrowser, post, request;

isRunningOnBrowser = require('./utils').isRunningOnBrowser;

request = require('superagent');

if (!isRunningOnBrowser) {
  request = request.agent();
}

Ajax = (function() {
  function Ajax(buffer) {
    this.xhr = null;
    this.donecb = null;
    this.failcb = null;
    this.request = request;
    this.buffer = buffer;
  }

  Ajax.prototype.get = function(params) {
    this.xhr = this.request.get(params);
    if (isRunningOnBrowser) {
      this.xhr.withCredentials();
    }
    if (this.buffer) {
      this.xhr.buffer();
    }
    this.xhr.end((function(_this) {
      return function(err, res) {
        return _this.end(err, res);
      };
    })(this));
    return this;
  };

  Ajax.prototype.post = function(params) {
    if ("data" in params) {
      this.xhr = this.request.post(params['url']).send(params['data']);
    } else {
      this.xhr = this.request.post(params);
    }
    if (isRunningOnBrowser) {
      this.xhr.withCredentials();
    }
    this.xhr.end((function(_this) {
      return function(err, res) {
        return _this.end(err, res);
      };
    })(this));
    return this;
  };

  Ajax.prototype.end = function(err, res) {
    if (err) {
      return this.failcb(err);
    } else {
      return this.donecb(res);
    }
  };

  Ajax.prototype["delete"] = function(params) {
    this.xhr = this.request.del(params);
    if (isRunningOnBrowser) {
      this.xhr.withCredentials();
    }
    this.xhr.end((function(_this) {
      return function(err, res) {
        return _this.end(err, res);
      };
    })(this));
    return this;
  };

  Ajax.prototype.done = function(cb) {
    return this.donecb = cb;
  };

  Ajax.prototype.fail = function(cb) {
    return this.failcb = cb;
  };

  return Ajax;

})();

get = function(params, buffer) {
  if (buffer == null) {
    buffer = false;
  }
  return new Ajax(buffer).get(params);
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

if (isRunningOnBrowser) {
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



},{"./utils":13,"superagent":undefined}],3:[function(require,module,exports){
var Config, ajax, events, utils;

events = require('./events');

utils = require('./utils');

ajax = require('./ajax');

Config = (function() {
  Config.debug = true;

  Config.EVENT_READY = 'config:ready.slsapi';

  Config.EVENT_FAIL = 'config:fail.slsapi';

  function Config(opcoes) {
    var self, xhr;
    this.id = utils.md5(JSON.stringify(opcoes));
    self = this;
    this.parseOpcoes(opcoes);
    if (opcoes.urlConfServico) {
      xhr = ajax.get(opcoes.urlConfServico);
      xhr.done(function(res) {
        self.parseOpcoes(res.body);
        return events.trigger(self.id, Config.EVENT_READY);
      });
      xhr.fail(function(err) {
        return events.trigger(self.id, Config.EVENT_FAIL, {
          err: err,
          message: 'Error: não foi possível carregar configuração da visualização'
        });
      });
    } else {
      setTimeout((function() {
        return events.trigger(self.id, Config.EVENT_READY);
      }), 5);
    }
  }

  Config.prototype.parseOpcoes = function(opcoes, view) {
    this.opcoes = new utils.Dicionario(opcoes);
    this.serverURL = this.opcoes.get('serverURL', this.serverURL || 'http://sl.wancharle.com.br');
    this.createURL = this.opcoes.get('createURL', this.createURL || (this.serverURL + "/note/create/"));
    this.loginURL = this.opcoes.get('loginURL', this.loginURL || (this.serverURL + "/user/login/"));
    this.logoutURL = this.opcoes.get('logoutURL', this.logoutURL || (this.serverURL + "/user/logout/"));
    this.notesURL = this.opcoes.get('notesURL', this.notesURL || (this.serverURL + "/note/"));
    this.notebookURL = this.opcoes.get('notebookURL', this.notebookURL || (this.serverURL + "/notebook/"));
    this.dataSources = this.opcoes.get('dataSources', this.dataSources || []);
    if (!view) {
      return this.coletorNotebookId = this.opcoes.get('id', '');
    }
  };

  return Config;

})();

module.exports = {
  'Config': Config
};



},{"./ajax":2,"./events":8,"./utils":13}],4:[function(require,module,exports){
var DataPool, DataSource, DataSourceCSV, DataSourceGoogle, createDataPool, createDataSource, events,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

events = require('./events');

DataSource = require('./datasource').DataSource;

DataSourceGoogle = require('./datasourceGoogle').DataSourceGoogle;

DataSourceCSV = require('./datasourceCSV').DataSourceCSV;

createDataSource = function(url, functionCode) {
  if (url.indexOf("docs.google.com/spreadsheet") > -1) {
    return new DataSourceGoogle(url, functionCode);
  } else {
    if (url.slice(-4) === ".csv") {
      return new DataSourceCSV(url, functionCode);
    } else {
      return new DataSource(url, functionCode);
    }
  }
};

createDataPool = function(config) {
  var instance;
  instance = DataPool.getInstance(config);
  if (instance) {
    instance.destroy();
  }
  instance = new DataPool();
  instance._constructor(config);
  return instance;
};

DataPool = (function() {
  function DataPool() {
    this.loadAllData = bind(this.loadAllData, this);
  }

  DataPool.EVENT_LOAD_START = 'datapool:start.slsapi';

  DataPool.EVENT_LOAD_STOP = 'datapool:stop.slsapi';

  DataPool.instances = {};

  DataPool.getInstance = function(config) {
    return this.instances[config.id];
  };

  DataPool.prototype._constructor = function(config) {
    var dataSources, index, j, len, s;
    DataPool.instances[config.id] = this;
    this.config = config;
    this.dataSources = [];
    dataSources = this.config.dataSources;
    for (index = j = 0, len = dataSources.length; j < len; index = ++j) {
      s = dataSources[index];
      this.addDataSource(s);
    }
    return events.on(config.id, DataSource.EVENT_LOADED, (function(_this) {
      return function() {
        return _this.onDataSourceLoaded();
      };
    })(this));
  };

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

  DataPool.prototype.loadAllData = function() {
    var i, j, len, obj, ref, results, source;
    obj = this;
    this.sourcesLoaded = 0;
    events.trigger(this.config.id, DataPool.EVENT_LOAD_START);
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
      return events.trigger(this.config.id, DataPool.EVENT_LOAD_STOP, this);
    }
  };

  DataPool.prototype.destroy = function() {
    events.off(this.config.id, DataSource.EVENT_LOADED);
    events.off(this.config.id, DataPool.EVENT_LOAD_START);
    return events.off(this.config.id, DataPool.EVENT_LOAD_STOP);
  };

  return DataPool;

})();

module.exports = {
  DataPool: DataPool,
  createDataPool: createDataPool
};



},{"./datasource":5,"./datasourceCSV":6,"./datasourceGoogle":7,"./events":8}],5:[function(require,module,exports){
var DataSource, ajax, contexto, events, utils,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

events = require('./events');

ajax = require('./ajax');

utils = require('./utils');

contexto = {};

contexto = utils;

DataSource = (function() {
  DataSource.EVENT_LOADED = 'datasourceLoaded.slsapi';

  DataSource.EVENT_LOAD_FAIL = 'datasourceLoadFail.slsapi';

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
      geoItem = func_convert(i, contexto);
    } catch (_error) {
      e = _error;
      console.error("Erro em DataSource::addItem: " + e.message, i);
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
      cat.push(geoItem);
    }
    return geoItem;
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
      return events.trigger(config.id, DataSource.EVENT_LOADED);
    } catch (_error) {
      e = _error;
      console.error(e.toString());
      events.trigger(config.id, DataSource.EVENT_LOAD_FAIL);
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

  return DataSource;

})();

module.exports = {
  DataSource: DataSource
};



},{"./ajax":2,"./events":8,"./utils":13}],6:[function(require,module,exports){
var DataSource, DataSourceCSV, ajax, csvParse, isRunningOnBrowser,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

DataSource = require('./datasource').DataSource;

ajax = require('./ajax');

isRunningOnBrowser = require('./utils').isRunningOnBrowser;

if (!isRunningOnBrowser) {
  csvParse = require('babyparse');
  DataSourceCSV = (function(superClass) {
    extend(DataSourceCSV, superClass);

    function DataSourceCSV() {
      return DataSourceCSV.__super__.constructor.apply(this, arguments);
    }

    DataSourceCSV.prototype.loadData = function(config) {
      var xhr;
      xhr = ajax.get(this.url, true);
      xhr.done((function(_this) {
        return function(res) {
          var json, parsed;
          parsed = csvParse.parse(res.text, {
            header: true
          });
          json = parsed.data;
          return _this.onDataLoaded(json, _this, config);
        };
      })(this));
      return xhr.fail(function(error) {
        return console.log('error ao baixar CSV', error);
      });
    };

    return DataSourceCSV;

  })(DataSource);
} else {
  csvParse = Papa;
  DataSourceCSV = (function(superClass) {
    extend(DataSourceCSV, superClass);

    function DataSourceCSV() {
      return DataSourceCSV.__super__.constructor.apply(this, arguments);
    }

    DataSourceCSV.prototype.loadData = function(config) {
      return csvParse.parse(this.url, {
        header: true,
        download: true,
        error: (function(_this) {
          return function() {
            return alert("Erro ao baixar arquivo csv da fonte de dados:\n" + _this.url);
          };
        })(this),
        complete: (function(_this) {
          return function(results, file) {
            return _this.onDataLoaded(results['data'], _this, config);
          };
        })(this)
      });
    };

    return DataSourceCSV;

  })(DataSource);
}

module.exports = {
  DataSourceCSV: DataSourceCSV
};



},{"./ajax":2,"./datasource":5,"./utils":13,"babyparse":undefined}],7:[function(require,module,exports){
var DataSource, DataSourceGoogle, TABLETOP, isRunningOnBrowser,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

isRunningOnBrowser = require('./utils').isRunningOnBrowser;

if (!isRunningOnBrowser) {
  TABLETOP = require('tabletop');
} else {
  TABLETOP = Tabletop;
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



},{"./datasource":5,"./utils":13,"tabletop":undefined}],8:[function(require,module,exports){
var bind, emitter, emitters, events, isRunningOnBrowser, select, trigger, unbind;

emitter = null;

isRunningOnBrowser = require('./utils').isRunningOnBrowser;

if (!isRunningOnBrowser) {
  events = require('events');
  emitters = {};
  select = function(id) {
    if (!(id in emitters)) {
      emitters[id] = new events.EventEmitter();
    }
    return emitters[id];
  };
  trigger = function(id, event, param) {
    return select(id).emit(event, param);
  };
  bind = function(id, event, cb) {
    return select(id).once(event, cb);
  };
  unbind = function(id, event, cb) {};
} else {
  select = function(id) {
    var target;
    target = $("#slEvent" + id);
    if (target.length <= 0) {
      target = $("<div id='slEvent" + id + "'> </div>");
      $("body").append(target);
    }
    return target;
  };
  trigger = function(id, event, param) {
    return select(id).trigger(event, param);
  };
  bind = function(id, event, cb) {
    var f;
    f = function(caller, params) {
      return cb(params);
    };
    return select(id).on(event, f);
  };
  unbind = function(id, event, cb) {
    return select(id).off(event);
  };
}

module.exports = {
  trigger: trigger,
  on: bind,
  off: unbind
};



},{"./utils":13,"events":undefined}],9:[function(require,module,exports){
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
    xhr.done(function(res) {
      return callback(res.body);
    });
    return xhr.fail(function(err) {
      return callbackFail(err);
    });
  };

  Notebook.prototype.getById = function(notebookId, callback, callbackFail) {
    var url, xhr;
    if (callbackFail == null) {
      callbackFail = null;
    }
    url = this.config.notebookURL + "?id=" + notebookId;
    xhr = ajax.get(url);
    xhr.done(function(res) {
      return callback(res.body);
    });
    return xhr.fail(function(err) {
      return callbackFail(err);
    });
  };

  return Notebook;

})();

module.exports = {
  'Notebook': Notebook
};



},{"./ajax":2}],10:[function(require,module,exports){
var Notes, ajax, events;

ajax = require('./ajax');

events = require('./events');

Notes = (function() {
  Notes.EVENT_ADD_NOTE_START = 'note:uploadStart.slsapi';

  Notes.EVENT_ADD_NOTE_FINISH = 'note:uploadFinish.slsapi';

  Notes.EVENT_ADD_NOTE_FAIL = 'note:uploadFail.slsapi';

  Notes.EVENT_DEL_NOTE_FAIL = 'note:deleteFail.slsapi';

  Notes.EVENT_DEL_NOTE_SUCCESS = 'note:deleteSUCCESS.slsapi';

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
    xhr.done(function(res) {
      return callback(res.body);
    });
    return xhr.fail(function(err) {
      return callback_fail(err);
    });
  };

  Notes.prototype.getByQuery = function(query, callback, callback_fail) {
    var xhr;
    xhr = ajax.get(this.config.notesURL + "?" + query);
    xhr.done(function(res) {
      return callback(res.body);
    });
    return xhr.fail(function(err) {
      return callback_fail(err);
    });
  };

  Notes.prototype.update = function(note_id, queryparams, callback, callback_fail) {
    var xhr;
    xhr = ajax.post({
      url: this.config.notesURL + "update/" + note_id + "/",
      data: queryparams
    });
    xhr.done(function(res) {
      return callback(res.body);
    });
    return xhr.fail(function(err) {
      return callback_fail(err);
    });
  };

  Notes.prototype["delete"] = function(note_id, callback) {
    var url, xhr;
    url = "" + this.config.notesURL + note_id;
    xhr = ajax.del(url);
    if (callback) {
      xhr.done(function(data) {
        return callback(data);
      });
    } else {
      xhr.done((function(_this) {
        return function(data) {
          return events.trigger(_this.config.id, Notes.EVENT_DEL_NOTE_SUCCESS, data);
        };
      })(this));
    }
    return xhr.fail((function(_this) {
      return function(err) {
        return events.trigger(_this.config.id, Notes.EVENT_DEL_NOTE_FAIL, err);
      };
    })(this));
  };

  Notes.prototype.enviar = function(note, notebookId, callback_ok, callback_fail) {
    var ft, options, params, xhr;
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
    events.trigger(this.config.id, Notes.EVENT_ADD_NOTE_START);
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
          events.trigger(_this.config.id, Notes.EVENT_ADD_NOTE_FINISH);
          return callback_ok(r);
        };
      })(this), (function(_this) {
        return function(error) {
          events.trigger(_this.config.id, Notes.EVENT_ADD_NOTE_FAIL);
          return callback_fail(error);
        };
      })(this), options);
    } else {
      xhr = ajax.post({
        url: this.config.createURL,
        data: params
      });
      xhr.done((function(_this) {
        return function(res) {
          events.trigger(_this.config.id, Notes.EVENT_ADD_NOTE_FINISH, res.body);
          return callback_ok(res.body);
        };
      })(this));
      return xhr.fail((function(_this) {
        return function(error) {
          events.trigger(_this.config.id, Notes.EVENT_ADD_NOTE_FAIL, error);
          return callback_fail(error);
        };
      })(this));
    }
  };

  return Notes;

})();

module.exports = {
  'Notes': Notes
};



},{"./ajax":2,"./events":8}],11:[function(require,module,exports){
var Config, Notebook, SLSAPI, User, ajax, dataPool, events, isRunningOnBrowser, notes;

isRunningOnBrowser = require('./utils').isRunningOnBrowser;

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

  SLSAPI.prototype.trigger = function(event, params) {
    return events.trigger(this.config.id, event, params);
  };

  SLSAPI.prototype.on = function(event, params) {
    return events.on(this.config.id, event, params);
  };

  SLSAPI.prototype.off = function(event, params) {
    return events.off(this.config.id, event, params);
  };

  return SLSAPI;

})();

SLSAPI.Config = Config;

SLSAPI.Notes = notes.Notes;

SLSAPI.User = User;

SLSAPI.dataPool = dataPool;

SLSAPI.ajax = ajax;

if (isRunningOnBrowser) {
  window.SLSAPI = SLSAPI;
}

module.exports = SLSAPI;



},{"./ajax":2,"./config":3,"./datapool":4,"./events":8,"./notebook":9,"./notes":10,"./user":12,"./utils":13}],12:[function(require,module,exports){
(function (process){
var CLIENT_SIDE, LocalStorage, User, ajax, events, localStorage, md5,
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

events = require('./events');

ajax = require('./ajax');

User = (function() {
  User.EVENT_LOGIN_SUCCESS = 'userLoginSuccess.slsapi';

  User.EVENT_LOGIN_START = 'userLoginStart.slsapi';

  User.EVENT_LOGIN_FINISH = 'userLoginFinish.slsapi';

  User.EVENT_LOGIN_FAIL = 'userLoginFail.slsapi';

  User.EVENT_LOGOUT_SUCCESS = 'userLogoutSuccess.slsapi';

  User.EVENT_LOGOUT_FAIL = 'userLogoutFail.slsapi';

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

  User.prototype.logout = function() {
    var xhr;
    this.storage.removeItem('Usuario');
    this.usuario = null;
    this.user_id = null;
    xhr = ajax.get(this.config.logoutURL);
    xhr.done((function(_this) {
      return function(req) {
        return events.trigger(_this.config.id, User.EVENT_LOGOUT_SUCCESS, req);
      };
    })(this));
    return xhr.fail((function(_this) {
      return function(req) {
        return events.trigger(_this.config.id, User.EVENT_LOGOUT_FAIL, req);
      };
    })(this));
  };

  User.prototype.login = function(u, p) {
    var url, xhr;
    if (u && p) {
      url = this.config.loginURL;
      events.trigger(this.config.id, User.EVENT_LOGIN_START);
      xhr = ajax.post({
        url: url,
        dataType: 'json',
        data: {
          username: u,
          password: p
        }
      });
      xhr.done((function(_this) {
        return function(res) {
          var json;
          json = res.body;
          if (json.error) {
            alert(json.error);
          } else {
            _this.setUsuario(u, json);
            events.trigger(_this.config.id, User.EVENT_LOGIN_SUCCESS, json);
          }
          return events.trigger(_this.config.id, User.EVENT_LOGIN_FINISH, json);
        };
      })(this));
      xhr.fail((function(_this) {
        return function(err) {
          return events.trigger(_this.config.id, User.EVENT_LOGIN_FAIL, err);
        };
      })(this));
    }
    return false;
  };

  return User;

})();

module.exports = {
  'User': User
};



}).call(this,require("/home/wancharle/searchlight-service-api/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js"))
},{"./ajax":2,"./events":8,"/home/wancharle/searchlight-service-api/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js":1,"blueimp-md5":undefined,"node-localstorage":undefined}],13:[function(require,module,exports){
(function (process){
var CLIENT_SIDE, Dicionario, dms2decPTBR, getURLParameter, md5, parseFloatPTBR, string2function,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

if (typeof process.browser === 'undefined') {
  md5 = require('blueimp-md5').md5;
  CLIENT_SIDE = false;
  dms2decPTBR = require('dms2dec-ptbr');
} else {
  CLIENT_SIDE = true;
  md5 = window.md5;
  dms2decPTBR = window.dms2decPTBR;
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
  re = /.*function *(\w*) *\( *([\w\,]*) *\) *\{/mg;
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
  md5: md5,
  dms2decPTBR: dms2decPTBR,
  isRunningOnBrowser: CLIENT_SIDE
};



}).call(this,require("/home/wancharle/searchlight-service-api/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js"))
},{"/home/wancharle/searchlight-service-api/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js":1,"blueimp-md5":undefined,"dms2dec-ptbr":undefined}]},{},[11]);
