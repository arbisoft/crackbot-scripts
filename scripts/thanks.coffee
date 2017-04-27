# Description:
#   Hubot responds any thank message politely. Phrases from:
#   http://www.macmillandictionary.com/thesaurus-category/british/Ways-of-accepting-someone-s-thanks
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot thank[s] [you] - Hubot accepts your thanks
#   thanks hubot - Hubot accepts your thanks
#
# Author:
#   github.com/delucas
#

cronJob = require('cron').CronJob
_ = require('underscore')

response = [
  "you're welcome",
  "no problem",
  "not a problem",
  "no problem at all",
  "don’t mention it",
  "it’s no bother",
  "it’s my pleasure",
  "my pleasure",
  "it’s nothing",
  "think nothing of it",
  "no, no. thank you!",
  "sure thing"
]

module.exports = (robot) ->
  robot.respond /thank(s| you)/i, (msg) ->
    msg.send msg.message.user.name.toLowerCase() + msg.random response
  thanks = new RegExp "thank(s| you) #{robot.name}", "i"
  robot.hear thanks, (msg) ->
    msg.send (msg.random response) + msg.message.user.name.toLowerCase()
