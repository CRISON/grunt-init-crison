express   = require "express"

exports.startServer = (port, publicPath, options = {}, callback) ->
  server = express()

  server.use express.static publicPath

  server.listen port

  console.log "Preview server running on port #{port}..."
