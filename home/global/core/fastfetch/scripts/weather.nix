{
  pkgs,
  lib,
  ...
}:
let
  jq = lib.getExe pkgs.jq;
in
pkgs.writeScript "weather" ''
  #!/usr/bin/env fish

  # INFO: Based on https://github.com/fcambus/ansiweather
  # Usage: ./weather.fish "Richmond,US"

  if not set -q argv[1]
      echo "Usage: ./weather <city>"
      exit 1
  end

  # URL-encode spaces in city name
  set CITY (echo $argv[1] | sed 's/ /%20/g')
  set API_KEY 85a4e3c55b73909f42c6a23ec35b7147

  if test -z "$API_KEY"
      echo "Please set the environment variable API_KEY"
      exit 1
  end

  set WEATHER_API_URL "https://api.openweathermap.org/data/2.5/weather?q=$CITY&units=metric&appid=$API_KEY"

  # Fetch current weather data
  set weather_data (curl -s "$WEATHER_API_URL")

  # Parse needed fields
  set city_name (set_color -i green)(echo $weather_data | ${jq} -r '.name')(set_color reset)
  set temperature (echo $weather_data | ${jq} -r '.main.temp' | xargs printf "%.0f")
  set humidity (echo $weather_data | ${jq} -r '.main.humidity')
  set weather_main (echo $weather_data | ${jq} -r '.weather[0].main')
  set lon (echo $weather_data | ${jq} -r '.coord.lon')
  set lat (echo $weather_data | ${jq} -r '.coord.lat')

  # Fetch UVI data
  set UVI_API_URL "https://api.openweathermap.org/data/2.5/uvi?lat=$lat&lon=$lon&appid=$API_KEY"
  set uvi_data (curl -s "$UVI_API_URL")
  set uvi (echo $uvi_data | ${jq} -r '.value')

  # Helper function for weather icon
  function weather_icon
    switch $argv[1]
      case "Clouds"
        echo "☁"
      case "Clear"
        echo "☀"
      case "Rain"
        echo "🌧"
      case "Snow"
        echo "❄"
      case "Thunderstorm"
        echo "⛈"
      case "Drizzle"
        echo "🌦"
      case "Mist" "Haze" "Fog" "Smoke" "Dust" "Sand" "Ash" "Squall" "Tornado"
        echo "🌫"
      case "*"
        echo "🌈"
    end
  end

  set icon (weather_icon $weather_main)

  printf "%s %s°C ⸗  %s ⸗  %s%% (%s)\n" $icon $temperature $uvi $humidity $city_name
''
