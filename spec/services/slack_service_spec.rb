require 'rails_helper'

RSpec.describe SlackService do
  let(:service){ SlackService.new }
  let(:weather_service){ WeatherService.new }
  let(:slack_client) { double('Slack::Web::Client.new') }
  let(:realtime_slack_client) { double('Slack::RealTime::Client.new') }

  context 'slack message' do
    it 'should render the table with weather data' do
      Timecop.freeze('2019-12-15 10:00:00') do
        VCR.use_cassette('weather_data') do
          table, icon = service.load_table_with_icon(
            'weather today', 'new york'
          )

          expect(icon).to eql(':rain_cloud:')
          expect(table.to_s).to eql(today_formatted_table)
        end
      end
    end

    it 'should send the weather data in real time chat' do
      Timecop.freeze('2019-12-15 10:00:00') do
        VCR.use_cassette('weather_data') do
          expect(service).to receive(:realtime_slack_client)
            .at_least(:once).and_return(realtime_slack_client)

          expect(realtime_slack_client).to receive(:message)
            .at_least(:once).and_return(true)

          expect(
            service.send_weather_message(
              'weather now', '#marcelo-interview-room', true
            )
          ).to eql(true)
        end
      end
    end

    it 'should send a daily message if weather changed significantly' do
      Timecop.freeze('2019-12-15 10:00:00') do
        VCR.use_cassette('weather_data') do
          expect(weather_service)
            .to receive(:sudden_weather_change?).at_least(:once).and_return(true)
          expect(service)
            .to receive(:weather_service).at_least(:once).and_return(weather_service)
          expect(service)
            .to receive(:slack_client).and_return(slack_client)
          expect(slack_client)
            .to receive(:chat_postMessage).at_least(:once).and_return(true)

          expect(service.daily_message).to eql(true)
        end
      end
    end
  end

  def today_formatted_table
    [
      '+------------+------------------------------------------+',
      '| Summary    | Light rain in the evening and overnight. |',
      '| High       | 38.14                                    |',
      '| Low        | 36.19                                    |',
      '| Humidity   | 0.64                                     |',
      '| Wind Speed | 4.29                                     |',
      '+------------+------------------------------------------+'
    ].join("\n")
  end
end
