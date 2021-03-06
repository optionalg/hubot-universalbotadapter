restify = require 'restify'
builder = require 'botbuilder'
{ Adapter, TextMessage } = require 'hubot'

class UniversalBotAdapter extends Adapter
  run: ->
    @server = restify.createServer()
    @robot.logger.info "Connector startup"

    @server.listen process.env.port || process.env.PORT || 3978, @listening

    @connector = new builder.ChatConnector {
      appId: process.env.MICROSOFT_APP_ID,
      appPassword: process.env.MICROSOFT_APP_PASSWORD
    }

    bot = new builder.UniversalBot @connector
    @server.post '/api/messages', @connector.listen()

    bot.dialog '/', @gotMessage

  gotMessage: (session, args, next) =>
    user = @robot.brain.userForId session.message.user.id, name: session.message.user.name

    selfName = session.message.text.replace(/<at>(.*)<\/at>.*/, '$1')
    @robot.name = selfName

    messageText = session.message.text.replace(/<at>/i, '').replace(/<\/at>\W*/i, ' ')
    message = new TextMessage(user, messageText)

    @session = session
    @receive message

  listening: () =>
    @robot.logger.info '%s listening to %s', @server.name, @server.url
    @emit 'connected'

  shutdown: () ->
    @robot.shutdown()
    process.exit 0

  send: (envelope, strings...) =>
    for string in strings
      @robot.logger.info "sending", string
      @session.send string

  reply: (envelope, strings...) =>
    for string in strings
      @session.send string

exports.UniversalBotAdapter = UniversalBotAdapter
