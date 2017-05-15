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


formatLogs = (projectLogs, username, totalPersons) ->
  sample1 = "Please complete your project logs for the following week(s):"
  sample2 = "Your project logs for weeks below are still not complete. "
  sample2 += "Please complete them as soon and accurately as possible. We need this information for billing purposes."
  sample3 = "You do know that the last 10 people to complete the logs owe a treat to the entire company, right? ;)"
  sample3 += "\nyou are one of the remaining " + totalPersons + " people who still haven't completed their project logs.\n"
  sample3 += sample1

  headingSamples = [sample1, sample2, sample3, sample3, sample3]

  date = new Date()
  day = date.getDay()
  todays_heading = headingSamples[day - 1]

  logs = "Hey @" + username

  logs += ",\n" + todays_heading + "\n"
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


sendMessageToUser = (robot, username, id, logs, userDetails, totalPersons) ->
  (robot.adapter.chatdriver.getDirectMessageRoomId username).then((DM) ->
    sendMessageToPersons(robot, userDetails, totalPersons)
    robot.adapter.chatdriver.sendMessageByRoomId logs, DM.rid

  , (error) ->
    if error.error == 'error-invalid-user'
      robot.logger.error error.error
      sendMessageToPersons(robot, userDetails, totalPersons)
    else
      user = {
        username: username,
        id: id
      }
      robot.logger.error error.error
      userDetails.push(user)
      setTimeout ->
        sendMessageToPersons(robot, userDetails, totalPersons)
      , 60000
  )

getProjectLogsStatus = (robot, username, id, userDetails, totalPersons) ->
  url = "https://hrdb.arbisoft.com/project-logs/incomplete-logs?person_id=#{id}"
  robot.http(url).get() (err, res, body) ->
    if res.statusCode isnt 200
      robot.logger.error res.statusCode + " " + url + " " + username
      sendMessageToPersons(robot, userDetails, totalPersons)
      return
    data = JSON.parse body
    if data.length != 0
      logs = formatLogs(data, username, totalPersons)
      sendMessageToUser(robot, username, id, logs, userDetails, totalPersons)
    else
      sendMessageToPersons(robot, userDetails, totalPersons)

sendMessageToPersons = (robot, userDetails, totalPersons) ->
  if userDetails.length != 0

    index = Math.floor(Math.random() * userDetails.length)
    user = (userDetails.splice(index, 1))[0]

    timeArray = [30000, 45000, 60000]
    timeIndex = Math.floor(Math.random() * timeArray.length)

    setTimeout ->
      getProjectLogsStatus(robot, user.username, user.id, userDetails, totalPersons)
    , timeArray[timeIndex]


getPersons = (robot) ->
  url = "https://hrdb.arbisoft.com/project-logs/incomplete-log-users"
  robot.http(url).get() (err, res, body) ->
    if res.statusCode isnt 200
      robot.logger.error "Request didn't come back HTTP 200 :("
      return

    data = JSON.parse body
    totalPersons = data.length
    if totalPersons != 0
      userDetails = []
      for person in data
        user = {
          username: person["username"],
          id: person["id"]
        }
        userDetails.push(user)
      sendMessageToPersons(robot, userDetails, totalPersons)


module.exports = (robot) ->

  cronJob = require('cron').CronJob

  new cronJob('00 00 12 * * 1-5', (->
    do everyDay
  ), null, true)

  everyDay = ->
    getPersons(robot)
