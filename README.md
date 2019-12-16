# Slack bot for weather

This is a simple rails application running a slack client that can:

  - Listen to requests for weather on a specific slack channel
  - Possible requests: 'weather today', 'weather tomorrow', 'weather yesterday', 'weather now'
  - Returns a data table with relevant info about the weather
  - Tries to match a weather icon

##WeatherService

- This service uses DarkSky.net service to fetch weather information about a location (i.e. New York).

- It will also calculate highs and lows between the current day and the previous day to determine whether a daily message is needed based on a bigger change in weather

##SlackService

- SlackService can be used with a single run (every day on a specific time using a scheduler with the rake task) or;

- Used as a websocket client, listening the Slack channel in real time (also available using a rake task)

The rake task for a real time bot is accessible via:

```rake weather:bot```

And the task to be run as a scheduler for every day:

```rake weather:morning```
