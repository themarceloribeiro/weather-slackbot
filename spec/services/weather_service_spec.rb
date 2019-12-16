require 'rails_helper'

RSpec.describe WeatherService do
  let(:service) { WeatherService.new }

  context '#location' do
    it 'should return geocoded information for the location', :vcr do
      VCR.use_cassette('geolocation') do
        expect(service.geocoded('New York')).to eql('40.7127281,-74.0060152')
      end
    end
  end

  context 'weather data' do
    it 'should return daily weather data for a specific location', :vcr do
      Timecop.freeze('2019-12-15 10:00:00') do
        VCR.use_cassette('weather_data') do
          expect(service.daily_data('New York')).to eql(new_york_data)
        end
      end
    end

    it 'should return weather rows for tomorrow' do
      Timecop.freeze('2019-12-15 10:00:00') do
        VCR.use_cassette('weather_data') do
          expect(service.weather_tomorrow('New York'))
            .to eql(new_york_data['2019-12-16'])
        end
      end
    end

    it 'should return whether weather changed significantly last day' do
      Timecop.freeze('2019-12-15 10:00:00') do
        VCR.use_cassette('weather_data') do
          expect(service.sudden_weather_change?('New York')).to eql(true)
        end
      end
    end
  end

  def new_york_data
    {
      '2019-12-14' => [%w[Icon partly-cloudy-day], ['Summary', 'Partly cloudy throughout the day.'], ['High', 48.42], ['Low', 34.12], ['Humidity', 0.57], ['Wind Speed', 13.17]],
      '2019-12-15' => [%w[Icon rain], ['Summary', 'Light rain in the evening and overnight.'], ['High', 38.14], ['Low', 36.19], ['Humidity', 0.64], ['Wind Speed', 4.29]],
      '2019-12-16' => [%w[Icon rain], ['Summary', 'Light rain until evening.'], ['High', 41.76], ['Low', 31.01], ['Humidity', 0.81], ['Wind Speed', 9.4]],
      '2019-12-17' => [%w[Icon clear-day], ['Summary', 'Clear throughout the day.'], ['High', 39.87], ['Low', 17.26], ['Humidity', 0.56], ['Wind Speed', 13.61]],
      '2019-12-18' => [%w[Icon clear-day], ['Summary', 'Clear throughout the day.'], ['High', 28.32], ['Low', 21.71], ['Humidity', 0.39], ['Wind Speed', 15.38]],
      '2019-12-19' => [%w[Icon clear-day], ['Summary', 'Clear throughout the day.'], ['High', 34.12], ['Low', 26.25], ['Humidity', 0.44], ['Wind Speed', 5.36]],
      '2019-12-20' => [%w[Icon snow], ['Summary', 'Possible drizzle in the evening and overnight.'], ['High', 40.17], ['Low', 36.26], ['Humidity', 0.6], ['Wind Speed', 4.69]],
      '2019-12-21' => [%w[Icon rain], ['Summary', 'Possible drizzle in the morning.'], ['High', 44.51], ['Low', 33.58], ['Humidity', 0.73], ['Wind Speed', 5.31]]
    }
  end
end
