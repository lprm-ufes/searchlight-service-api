// Generated by CoffeeScript 1.9.2
(function() {
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

}).call(this);