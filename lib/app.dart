import 'package:flutter/material.dart';
import 'package:weather_app/weather_screen.dart';

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather APP',
      debugShowCheckedModeBanner: false,
      home: WeatherScreen(),
    );
  }
}
