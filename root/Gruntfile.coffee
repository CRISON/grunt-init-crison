server = require "./server"
bower  = require "bower"

module.exports = (grunt) ->
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-concat"
  grunt.loadNpmTasks "grunt-contrib-stylus"
  grunt.loadNpmTasks "grunt-contrib-jade"
  grunt.loadNpmTasks "grunt-contrib-copy"
  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-karma"
  grunt.loadNpmTasks "grunt-contrib-uglify"
  grunt.loadNpmTasks "grunt-replace"

  appJsFiles = [
    "app/scripts/**/*"
  ]

  spawn = (options, done = ->) ->
    options.opts ?= stdio: "inherit"
    grunt.util.spawn options, done

  runDevelopment = (options = {}) ->
    testNeeded  = options.test?

    serverArgs = ["server"]

    @async()

    spawn
      grunt: true
      args: ["build"]
    , ->
      spawn
        grunt: true
        args: ["watch"]

      spawn
        grunt: true
        args: serverArgs

      if testNeeded
        spawn
          grunt: true
          args: ["karma"]

  grunt.initConfig
    coffee:
      "build/scripts/app.js":   appJsFiles

    concat:
      js:
        dest: "build/scripts/vendor.js"
        src: [
          'vendor/scripts/**/*'
        ]
      css:
        dest: "build/css/vendor.css"
        src:  ["vendor/styles/**/*"]

    stylus:
      compile:
        options:
          use: [require "nib"]
        files:
          "build/css/app.css":   ["app/styles/**/*"]

    jade:
      files:
        expand: true
        cwd: "app"
        src: [
          "index.jade"
        ]
        ext: ".html"
        dest: "build"

    copy:
      assets:
        files: [
          expand: true
          src: ["app/assets/**"]
          dest: "build/"
          rename: (dest, src) ->
            dest + src.slice "app/assets/".length
        ]

    clean:
      temp:   ["tmp"]
      build:  ["build"]
      public: ["public"]

    karma:
      unit:
        configFile: "karma.conf.js"
        autoWatch: true

    watch:
      js:
        files: ["app/**/*.coffee"]
        tasks: ["coffee", "concat:js"]
        options: interrupt: true
      css:
        files: ["app/**/*.styl"]
        tasks: ["stylus", "clean:temp"]
        options: interrupt: true
      jade:
        files: ["app/**/*.jade"]
        tasks: ["jade", "replace"]
        options: interrupt: true

    replace:
      deploy:
        options:
          variables:
            "timestamp": "<%= (new Date()).getTime() %>"
          prefix: "@@"
        files:
          "build/index.html": "build/index.html"

    uglify:
      options:
        report: "min"
      deploy:
        files:[
          expand: true
          cwd: "build/scripts"
          src: ["*.js", "!login.js"]
          ext: ".js"
          dest: "build/scripts"
        ]

  grunt.registerTask "build", "Build files to build/ for development", [
    "clean"
    "copy:assets"
    "coffee"
    "stylus"
    "jade"
    "concat"
    "clean:temp"
    "replace"
  ]

  grunt.registerTask "bower:list", "List all bower packages paths", ->
    done = @async()
    bower.commands
      .list({paths: true})
      .on("data", (data)->
        console.log data
        done()
      )

  grunt.registerTask "deploy", "Build for deployment", ->
    appJsFiles.pop()
    grunt.task.run ["build", "uglify"]

  grunt.registerTask "run", "Watch app/ and run test server", ->
    runDevelopment.call this, {}

  grunt.registerTask "go", "Runs watch, server, and test", ->
    runDevelopment.call this, {test: true}

  grunt.registerTask "server", "Run test server", ->
    target = grunt.option("target") or "local"
    @async()

    options = {}

    server.startServer 6400, "build", options

  grunt.registerTask "tag", "Update Version", ->
    version = "#{grunt.option("tag")}"

    unless version?
      grunt.fail.fatal "Missing tag"

    unless version.split(".").length is 3
      grunt.fail.fatal "Invalid tag"

    data         = grunt.file.readJSON 'package.json'
    data.version = version
    grunt.file.write "./package.json", JSON.stringify(data, undefined, '  ')

    done = @async()
    spawn
      cmd:  "git"
      args: ["commit", "-am", "Version bump #{version}"]
    , ->
      grunt.log.writeln "Bumped package.json version to #{version}"

      spawn
        cmd:  "git"
        args: ["tag", version]
      , ->
        grunt.log.writeln "Added tag #{version} to HEAD"
        done()

