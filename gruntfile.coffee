module.exports = (grunt) ->
  grunt.initConfig
    browserify:
      dist:
        files:
          './dist/slsapi.js':['./src/slsapi.coffee'] 
        options:
          browserifyOptions:
            debug: grunt.option('debug')
            transform: [ 'coffeeify']

    watch:
      files: ['src/*.coffee']
      tasks: ['browserify']

  grunt.loadNpmTasks 'grunt-browserify'
  grunt.registerTask 'default', ['browserify']

# vim: set ts=2 sw=2 sts=2 expandtab:

