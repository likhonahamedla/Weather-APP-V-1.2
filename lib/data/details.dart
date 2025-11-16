import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/main.dart';

Map<int, dynamic> wmoCodeMap = {
  0: {'icon': Icons.wb_sunny, 'description': 'Clear sky'},
  1: {'icon': Icons.cloud, 'description': 'Mostly clear'},
  2: {'icon': Icons.cloud, 'description': 'Partly cloudy'},
  3: {'icon': Icons.cloud_queue, 'description': 'Overcast'},
  45: {'icon': Icons.foggy, 'description': 'Fog'},
  48: {'icon': Icons.ac_unit, 'description': 'Depositing Rime Fog'},
  51: {'icon': Icons.grain, 'description': 'Light Drizzle'},
  53: {'icon': Icons.grain, 'description': 'Moderate Drizzle'},
  55: {'icon': Icons.grain, 'description': 'Heavy Drizzle'},
  61: {'icon': Icons.beach_access, 'description': 'Light Rain'},
  63: {'icon': Icons.beach_access, 'description': 'Moderate Rain'},
  65: {'icon': Icons.beach_access, 'description': 'Heavy Rain'},
  80: {'icon': Icons.beach_access, 'description': 'Slight Showers'},
  81: {'icon': Icons.beach_access, 'description': 'Moderate Showers'},
  82: {'icon': Icons.beach_access, 'description': 'Violent Showers'},
  95: {'icon': Icons.flash_on, 'description': 'Thunderstorm'},
  96: {'icon': Icons.flash_on, 'description': 'Thunderstorm & Hail'},
  -1: {'icon': Icons.cloud, 'description': 'Weather Unknown'},
};

Map<String, dynamic> getWeatherInfo(int code) {
  return wmoCodeMap[code] ?? wmoCodeMap[-1];
}

class CurrentWeather {
  final double temperature;
  final int weatherCode;
  final double windSpeed;
  final String time;

  CurrentWeather({
    required this.temperature,
    required this.weatherCode,
    required this.windSpeed,
    required this.time,
  });
}

class HourlyData {
  final String time;
  final double temperature;
  final int weatherCode;

  HourlyData({
    required this.time,
    required this.temperature,
    required this.weatherCode,
  });
}

class DailyData {
  final String date;
  final double maxTemp;
  final double minTemp;
  final String sunrise;
  final String sunset;
  DailyData({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.sunrise,
    required this.sunset,
  });
}

class WeatherData {
  final CurrentWeather current;
  final List<HourlyData> hourly;
  final List<DailyData> daily;

  WeatherData({
    required this.current,
    required this.hourly,
    required this.daily,
  });
}

Future<WeatherData> fetchWeather(double latitude, double longitude) async {
  final url = Uri.parse(
    'https://api.open-meteo.com/v1/forecast'
    '?latitude=$latitude&longitude=$longitude'
    '&current=temperature_2m,weather_code,wind_speed_10m'
    '&hourly=temperature_2m,weather_code'
    '&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset'
    '&forecast_days=10'
    '&timezone=Asia%2FDhaka',
  );
  final response = await http.get(url);
  final Map<String, dynamic> decodeData = jsonDecode(response.body);

  if (response.statusCode == 200) {
    final currentRaw = decodeData['current'] as Map<String, dynamic>;
    final CurrentWeather current = CurrentWeather(
      temperature: currentRaw['temperature_2m'] as double,
      weatherCode: currentRaw['weather_code'] as int,
      windSpeed: currentRaw['wind_speed_10m'] as double,
      time: currentRaw['time'] as String,
    );
    final hourlyRaw = decodeData['hourly'] as Map<String, dynamic>;
    final List<String> hourlyTime = (hourlyRaw['time'] as List<dynamic>)
        .cast<String>();
    final List<double> hourlyTemp =
        (hourlyRaw['temperature_2m'] as List<dynamic>).cast<double>();
    final List<int> hourlyCode = (hourlyRaw['weather_code'] as List<dynamic>)
        .cast<int>();
    final List<HourlyData> hourlyList = [];
    for (int i = 0; i < 24 && i < hourlyTime.length; i++) {
      hourlyList.add(
        HourlyData(
          time: hourlyTime[i],
          temperature: hourlyTemp[i],
          weatherCode: hourlyCode[i],
        ),
      );
    }
    final dailyRaw = decodeData['daily'] as Map<String, dynamic>;
    final List<String> dailyDates = (dailyRaw['time'] as List<dynamic>)
        .cast<String>();
    final List<double> dailyMax =
        (dailyRaw['temperature_2m_max'] as List<dynamic>).cast<double>();
    final List<double> dailyMin =
        (dailyRaw['temperature_2m_min'] as List<dynamic>).cast<double>();
    final List<String> dailySunrise = (dailyRaw['sunrise'] as List<dynamic>)
        .cast<String>();
    final List<String> dailySunset = (dailyRaw['sunset'] as List<dynamic>)
        .cast<String>();
    final List<DailyData> dailyList = [];
    for (int i = 0; i < dailyDates.length; i++) {
      dailyList.add(
        DailyData(
          date: dailyDates[i],
          maxTemp: dailyMax[i],
          minTemp: dailyMin[i],
          sunrise: dailySunrise[i],
          sunset: dailySunset[i],
        ),
      );
    }
    return WeatherData(current: current, hourly: hourlyList, daily: dailyList);
  } else {
    throw Exception(
      'Failed to load weather data.statusCode: ${response.statusCode}',
    );
  }
}
