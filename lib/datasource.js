// Generated by CoffeeScript 1.10.0
(function() {
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

    DataSource.EVENT_REQUEST_FAIL = 'datasourceRequestFail.slsapi';

    DataSource.hashItem = function(item) {
      return "" + (parseFloat(item.latitude).toFixed(7)) + (parseFloat(item.longitude).toFixed(7)) + (utils.md5(JSON.stringify(item)));
    };

    DataSource.getNotesReadURLByPosition = function(mashup, position, nbID) {
      var url;
      url = (mashup.config.toJSON().notesReadURL) + "lista/?limit=100&notebook=" + nbID + "&lat=" + position.latitude + "&lng=" + position.longitude + "&distance=" + position.distance;
      return url;
    };

    function DataSource(url, func_code, i) {
      this.addItem = bind(this.addItem, this);
      this._getCatOrCreate = bind(this._getCatOrCreate, this);
      var e, error;
      this.index = i;
      this.valid = true;
      if (url && typeof func_code === 'function') {
        this.url = url;
        this.func_code = func_code;
      } else {
        if (typeof func_code === 'string') {
          try {
            this.func_code = utils.string2function(func_code);
            this.url = url;
          } catch (error) {
            e = error;
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
      this.resetData();
      this.cachedSource = {
        url: url,
        func_code: function(i) {
          return i;
        }
      };
    }

    DataSource.prototype.resetData = function() {
      this.notes = [];
      this.notesChildren = {};
      this.categories = {};
      return this.categories_id = {};
    };

    DataSource.prototype.toJSON = function() {
      return {
        'func_code': this.func_code.toString(),
        'url': this.url,
        'cachedURL': this.cachedUrl
      };
    };

    DataSource.prototype.isValid = function() {
      return this.valid;
    };

    DataSource.prototype._getCatOrCreate = function(catName, catId) {
      var cat;
      if (!catName) {
        catName = "Sem Categoria";
      }
      cat = this.categories[catName];
      if (cat) {
        return cat;
      } else {
        this.categories[catName] = [];
        this.categories_id[catName] = catId;
        return this.categories[catName];
      }
    };

    DataSource.prototype.addItem = function(i, func_convert) {
      var cat, e, error, geoItem;
      try {
        geoItem = func_convert(i, contexto);
      } catch (error) {
        e = error;
        console.error("Erro em DataSource::addItem: " + e.message, i);
        geoItem = null;
      }
      if (geoItem) {
        if (!geoItem.id) {
          geoItem.hashid = DataSource.hashItem(geoItem);
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
        cat = this._getCatOrCreate(geoItem.cat || geoItem.categoria, geoItem.cat_id);
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

    DataSource.prototype.canLoadFromCache = function(mashup) {
      var can;
      can = mashup.useCache && this.url.indexOf(mashup.config.serverURL) === -1;
      return can;
    };

    DataSource.prototype.load = function(mashup, force, position) {
      if (force == null) {
        force = "";
      }
      this.resetData();
      if (this.canLoadFromCache(mashup)) {
        if (this.cachedURL) {
          return this.loadFromCache(mashup, position);
        } else {
          return this.getCachedURL(mashup, force, (function(_this) {
            return function() {
              return _this.loadFromCache(mashup, position);
            };
          })(this));
        }
      } else {
        return this.loadData(mashup, position);
      }
    };

    DataSource.prototype.loadData = function(mashup, position) {
      var url, xhr;
      if (position) {
        this.notebookID = this.url.split('notebook=')[1];
        url = DataSource.getNotesReadURLByPosition(mashup, position, this.notebookID);
      } else {
        url = this.url;
      }
      xhr = ajax.get(url, {
        type: 'json'
      });
      xhr.done((function(_this) {
        return function(res) {
          var json;
          json = res.body;
          if (res.type.toLowerCase().indexOf("text") > -1) {
            json = JSON.parse(res.text);
          }
          return _this.onDataLoaded(json, _this, mashup);
        };
      })(this));
      return xhr.fail(function(err) {
        return events.trigger(mashup.config.id, DataSource.EVENT_REQUEST_FAIL, err);
      });
    };

    DataSource.prototype.loadFromCache = function(mashup, position) {
      var url, xhr;
      if (position) {
        url = this.cachedURL + "&limit=100&lat=" + position.latitude + "&lng=" + position.longitude + "&distance=" + position.distance;
      } else {
        url = this.cachedURL + "&limit=1000 ";
      }
      xhr = ajax.get(url, {
        type: 'json'
      });
      xhr.done((function(_this) {
        return function(res) {
          var json;
          json = res.body;
          if (res.type.toLowerCase().indexOf("text") > -1) {
            json = JSON.parse(res.text);
          }
          return _this.onDataLoaded(json, _this.cachedSource, mashup);
        };
      })(this));
      return xhr.fail(function(err, res) {
        return events.trigger(mashup.config.id, DataSource.EVENT_REQUEST_FAIL, err);
      });
    };

    DataSource.prototype.getCachedURL = function(mashup, forceImport, cb) {
      var url, xhr;
      if (forceImport == null) {
        forceImport = "";
      }
      url = mashup.cacheURL + "?mashupid=" + mashup.id + "&fonteIndex=" + this.index + "&forceImport=" + forceImport;
      xhr = ajax.get(url, {
        type: 'json'
      });
      xhr.done((function(_this) {
        return function(res) {
          _this.cachedURL = res.body.cachedUrl;
          return cb();
        };
      })(this));
      return xhr.fail((function(_this) {
        return function(err) {
          if (err.status === 400) {
            return _this.loadData(mashup);
          } else {
            return console.log(err);
          }
        };
      })(this));
    };

    DataSource.prototype.onDataLoaded = function(data, fonte, mashup) {
      var d, e, error, i, j, len;
      try {
        for (i = j = 0, len = data.length; j < len; i = ++j) {
          d = data[i];
          this.addItem(d, fonte.func_code);
        }
        return events.trigger(mashup.config.id, DataSource.EVENT_LOADED);
      } catch (error) {
        e = error;
        console.error(e.toString());
        events.trigger(mashup.config.id, DataSource.EVENT_LOAD_FAIL);
      }
    };

    return DataSource;

  })();

  module.exports = {
    DataSource: DataSource
  };

}).call(this);
