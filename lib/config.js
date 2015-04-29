// Generated by CoffeeScript 1.9.2
(function() {
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

}).call(this);