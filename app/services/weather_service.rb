class WeatherService
  ALLOWED_DELTA = 10.0
  TIMEZONE = 'America/Los_Angeles'

  def weather_api
    "https://api.darksky.net/forecast/#{ENV['DARKSKY_TOKEN']}"
  end

  def data_keys
    {
      icon: 'Icon',
      summary: 'Summary',
      temperature: 'Temperature',
      temperatureHigh: 'High',
      temperatureLow: 'Low',
      humidity: 'Humidity',
      windSpeed: 'Wind Speed'
    }
  end

  def geocoded(location)
    loc = Geocoder.search(location).first
    "#{loc.latitude},#{loc.longitude}"
  end

  def data(location)
    JSON.parse(RestClient.get(
      "#{weather_api}/#{geocoded(location)}"
    ).body)
  end

  def daily_data(location)
    data(location)['daily']['data'].each_with_object({}) do |d, hash|
      date_key = Time.at(d['time']).strftime('%Y-%m-%d')
      rows = data_keys.keys.map do |key|
        [data_keys[key], d[key.to_s]] if d[key.to_s].present?
      end.compact

      hash[date_key] = rows
    end
  rescue StandardError
    {}
  end

  def weather_now(location)
    d = data(location)['currently']
    data_keys.keys.map do |key|
      [data_keys[key], d[key.to_s]] if d[key.to_s].present?
    end.compact
  rescue StandardError => e
    Rails.logger.fatal("Could not retrieve weather for #{location}")
    Rails.logger.fatal(e.backtrace)
  end

  def weather_yesterday(location)
    weather_on(location, 1.day.ago.in_time_zone(TIMEZONE).strftime('%Y-%m-%d'))
  end

  def weather_today(location)
    weather_on(location, Time.now.in_time_zone(TIMEZONE).strftime('%Y-%m-%d'))
  end

  def weather_tomorrow(location)
    weather_on(location, 1.day.from_now.in_time_zone(TIMEZONE).strftime('%Y-%m-%d'))
  end

  def weather_on(location, date)
    data = daily_data(location)[date]
    unless data.present?
      raise "Could not retrieve weather data for #{location} on #{date}"
    end

    data
  end

  def sudden_weather_change?(location)
    yesterday       = weather_yesterday(location)
    today           = weather_today(location)
    yesterday_high  = yesterday[2].last
    today_high      = today[2].last
    yesterday_low   = yesterday[3].last
    today_low       = today[3].last
    delta_high      = yesterday_high - today_high
    delta_low       = yesterday_low - today_low

    delta_low.abs > ALLOWED_DELTA || delta_high.abs > ALLOWED_DELTA
  end
end
