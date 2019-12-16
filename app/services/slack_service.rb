class SlackService

  LOCATION = 'New York'.freeze
  CHANNEL  = '#marcelo-interview-room'.freeze

  def weather_service
    @weather_service ||= WeatherService.new
  end

  def realtime_slack_client
    @realtime_slack_client ||= Slack::RealTime::Client.new
  end

  def slack_client
    @slack_client = Slack::Web::Client.new
  end

  def start
    realtime_slack_client.on :message do |data|
      send_weather_message(data.text, data.channel, true)
    end

    realtime_slack_client.start!
  end

  def load_table_with_icon(request, location)
    table_rows = weather_service.send(request.downcase.tr(' ', '_'), location)

    # Let's try to show a nice slack emoji
    icon = table_rows.shift
    icon[1] = emoji_for(icon[1])

    [Terminal::Table.new(rows: table_rows), icon[1]]
  end

  def send_weather_message(request, channel = CHANNEL, real_time = false)
    location = LOCATION
    table, icon = load_table_with_icon(request, location)
    text = "#{request.titleize} in #{location}: #{icon} ```#{table}```"

    if real_time
      realtime_slack_client.message(channel: channel, text: text)
    else
      slack_client.chat_postMessage(
        channel: channel,
        text: "@channel #{text}",
        as_user: true
      )
    end
  rescue StandardError => e
    Rails.logger.fatal("[WEATHER BOT] Ignoring message: #{request}")
    Rails.logger.fatal(e.backtrace)
  end

  def daily_message
    return unless weather_service.sudden_weather_change?(LOCATION)

    send_weather_message('Weather today')
  end

  def emoji_for(icon)
    case icon
    when 'clear-night'
      ':night_with_stars:'
    when 'rain'
      ':rain_cloud:'
    when 'partly-cloudy-night'
      ':cloud:'
    else
      "#{icon} :question:"
    end
  end
end
