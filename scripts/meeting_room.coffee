# Description:
#   Get meeting rooms status
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot meeting rooms
#
# Author:
#   Ikram <ikram.ali@arbisoft.com>


getRoomsStatus = (msg) ->
  msg.http('http://meeting-room-status.s3.amazonaws.com/r.json')
  .get() (err, res, body) ->
    results = JSON.parse(body)

    for r in results
      msg.send r

module.exports = (robot) ->
  robot.respond /meeting rooms/i, (msg) ->
    getRoomsStatus(msg)
