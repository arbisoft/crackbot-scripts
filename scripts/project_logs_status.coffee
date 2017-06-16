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


formatLogs = (projectLogs, username, logsMsgSample) ->
  todays_heading = logsMsgSample.msg

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

  logsMsg = {
    msg: logs,
    attachments: [{
      image_url: logsMsgSample.link
    }]
  }
  return logsMsg


sendMessageToUser = (robot, user, logsMsg, userDetails, logsMsgSample) ->
  (robot.adapter.chatdriver.getDirectMessageRoomId user.username).then((DM) ->
    sendMessageToPersons(robot, userDetails, logsMsgSample)
    robot.adapter.chatdriver.sendMessageByRoomId logsMsg, DM.rid

  , (error) ->
    if error.error == 'error-invalid-user'
      robot.logger.error error.error
      sendMessageToPersons(robot, userDetails, logsMsgSample)
    else
      robot.logger.error error.error
      userDetails.push(user)
      setTimeout ->
        sendMessageToPersons(robot, userDetails, logsMsgSample)
      , 60000
  )

getProjectLogsStatus = (robot, user, userDetails, logsMsgSample) ->
  url = "https://hrdb.arbisoft.com/project-logs/incomplete-logs?person_id=#{user.id}"
  robot.http(url).get() (err, res, body) ->
    if res.statusCode isnt 200
      robot.logger.error res.statusCode + " " + url + " " + user.username
      sendMessageToPersons(robot, userDetails, logsMsgSample)
      return
    data = JSON.parse body
    if data.length != 0
      logsMsg = formatLogs(data, user.username, logsMsgSample)
      sendMessageToUser(robot, user, logsMsg, userDetails, logsMsgSample)
    else
      sendMessageToPersons(robot, userDetails, logsMsgSample)

sendMessageToPersons = (robot, userDetails, logsMsgSample) ->
  if userDetails.length != 0

    index = Math.floor(Math.random() * userDetails.length)
    user = (userDetails.splice(index, 1))[0]

    timeArray = [30000, 45000, 60000]
    timeIndex = Math.floor(Math.random() * timeArray.length)

    setTimeout ->
      getProjectLogsStatus(robot, user, userDetails, logsMsgSample)
    , timeArray[timeIndex]


getMessageSampleByDay = (robot, userDetails, totalPersons) ->
  url = 'http://crackbot-reminders.s3.amazonaws.com/project-logs-reminder/logs.json'
  robot.http(url).get() (err, res, body) ->
    if res.statusCode isnt 200
      robot.logger.error res.statusCode + " " + url
      return

    complete_week = JSON.parse body
    date = new Date()
    day = date.getDay()
    week_days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday']
    current_day = week_days[day - 1]
    current_day_samples = complete_week[current_day]
    index = Math.floor(Math.random() * current_day_samples.length)
    selected_sample = current_day_samples[index]

    logsMsgSample = {
      msg: selected_sample['text_message'].replace("totalPersons", totalPersons.toString()),
      link: selected_sample['link']
    }
    sendMessageToPersons(robot, userDetails, logsMsgSample)

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
      getMessageSampleByDay(robot, userDetails, totalPersons)


module.exports = (robot) ->

  cronJob = require('cron').CronJob

  new cronJob('00 00 12 * * 1-5', (->
    do everyDay
  ), null, true)

  everyDay = ->
    getPersons(robot)
