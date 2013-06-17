Net = require 'net'
debug = require('debug')('adb:connection')
{EventEmitter} = require 'events'
{execFile} = require 'child_process'

Parser = require './parser'

class Connection extends EventEmitter
  constructor: (@options) ->
    @socket = null
    @parser = null
    @triedStarting = false

  connect: ->
    @socket = Net.connect @options
    @parser = new Parser @socket
    @socket.on 'connect', =>
      this.emit 'connect'
    @socket.on 'end', =>
      this.emit 'end'
    @socket.on 'timeout', =>
      this.emit 'timeout'
    @socket.on 'error', (err) =>
      this._handleError err
    @socket.on 'close', (hadError) =>
      this.emit 'close', hadError
    return this

  end: ->
    @socket.end()
    return this

  startServer: (callback) ->
    debug "Starting ADB server via '#{@options.bin} start-server'"
    execFile @options.bin, ['start-server'], {}, callback
    return this

  _handleError: (err) ->
    if err.code is 'ECONNREFUSED' and not @triedStarting
      debug "Connection was refused, let's try starting the server once"
      @triedStarting = true
      this.startServer (err) =>
        return this._handleError err if err
        this.connect()
    else
      debug "Connection had an error: #{err.message}"
      this.emit 'error', err
      this.end()
    return

module.exports = Connection