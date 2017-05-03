# Description:
#   Get Person Project Logs status
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   None
#
# Author:
#   Tayyab <tayyab.razzaq@arbisoft.com>



formatLogs = (projectLogs, username) ->
  logs = "Hey @" + username
  logs += ",\nPlease complete your project logs for the following week(s):\n"
  for person_week_log in projectLogs
    person_week_projects = person_week_log['person_week_projects']
    projects = ""
    if person_week_projects.length != 0
      projects = " ( "
      first = true
      for projectTeam in person_week_projects
        if first is false
          projects += ' , '
        else
          first = false
        projects += projectTeam['team'] + '-' + projectTeam['subteam']
      projects += " )"
    logs += person_week_log['week_starting'] + " to " + person_week_log['week_ending'] + projects + "\n"
  logs += "To complete the logs, go to https://hrdb.arbisoft.com/app\nThank you!"
  return logs


sendMessageToUser = (robot, username, id, logs, userDetails) ->
  (robot.adapter.chatdriver.getDirectMessageRoomId username).then( (DM) ->
    sendMessageToPersons(robot, userDetails)
    robot.adapter.chatdriver.sendMessageByRoomId logs, DM.rid

  , (error) ->
    if error.error == 'error-invalid-user'
      robot.logger.error error.error
      sendMessageToPersons(robot, userDetails)
    else
      user = {
        username: username,
        id: id
      }
      robot.logger.error error.error
      userDetails.push(user)
      setTimeout ->
        sendMessageToPersons(robot, userDetails)
      ,60000
  )

getProjectLogsStatus = (robot, username, id, userDetails) ->
  url = "https://hrdb.arbisoft.com/project-logs/incomplete-logs?person_id=#{id}"
  robot.http(url).header('Accept', 'application/json', 'Cache-Control': 'no-cache', 'Connection': 'keep-alive', 'Allow': 'GET, HEAD, OPTIONS').get() (err, res, body) ->
    if res.statusCode isnt 200
      robot.logger.error res.statusCode + " " + url + " " + username
      sendMessageToPersons(robot, userDetails)
      return
    data = JSON.parse body
    if data.length != 0
      logs = formatLogs(data, username)
      sendMessageToUser(robot, username, id, logs, userDetails)
    else
      sendMessageToPersons(robot, userDetails)

sendMessageToPersons = (robot , userDetails) ->
  if userDetails.length != 0
    user = userDetails.pop()
    setTimeout ->
      getProjectLogsStatus(robot, user.username, user.id, userDetails)
    ,1000

getPersons = (robot) ->
  url = "https://hrdb.arbisoft.com/project-logs/incomplete-log-users"
  robot.http(url).get() (err, res, body) ->
    if res.statusCode isnt 200
      robot.logger.error "Request didn't come back HTTP 200 :("
      return

    data = JSON.parse body
    if data.length != 0
      userDetails = []
      for person in data
        user = {
          username: person["username"],
          id: person["id"]
        }
        userDetails.push(user)
      sendMessageToPersons(robot, userDetails)


module.exports = (robot) ->

  cronJob = require('cron').CronJob

  new cronJob('00 00 16 * * 1-5', (->
    do everyDay
  ), null, true)

  everyDay = ->
    getPersons(robot)
