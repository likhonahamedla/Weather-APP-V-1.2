import 'package:flutter/material.dart';
import 'package:weather_app/data/details.dart';

enum WeatherState { loading, success, error }

WeatherState _currentState = WeatherState.loading;

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final double defaultLat = 23.77;
  final double defaultLon = 90.39;

  double _minDailyTemp = 0.0;
  double _maxDailyTemp = 0.0;

  WeatherData? _weatherData;
  String _errorMessage = '';

  final TextEditingController _cityController = TextEditingController(
    text: 'Dhaka',
  );

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _currentState = WeatherState.loading;
    });

    try {
      final data = await fetchWeather(defaultLat, defaultLon);

      final dailyTemps = data.daily
          .map((d) => [d.minTemp, d.maxTemp])
          .expand((t) => t)
          .toList();
      _minDailyTemp = dailyTemps.reduce((a, b) => a < b ? a : b);
      _maxDailyTemp = dailyTemps.reduce((a, b) => a > b ? a : b);

      setState(() {
        _weatherData = data;
        _currentState = WeatherState.success;
      });
    } catch (e) {
      setState(() {
        _currentState = WeatherState.error;
        _errorMessage =
            'Failed to load weather data. Please check your connection.';
      });
    }
  }

  Widget _buildCurrentWeather(CurrentWeather current, DailyData todayForecast) {
    final info = getWeatherInfo(current.weatherCode);
    final isDay =
        DateTime.parse(current.time).hour > 6 &&
        DateTime.parse(current.time).hour < 18;
    final highTemp = todayForecast.maxTemp.toStringAsFixed(0);
    final lowTemp = todayForecast.minTemp.toStringAsFixed(0);

    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'MY LOCATION',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Dhaka, Bangladesh',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${current.temperature.toStringAsFixed(0)}°',
          style: TextStyle(
            color: Colors.white,
            fontSize: 90,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          '${info['description']}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'H: $highTemp° L: $lowTemp°',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            '${info['description']} conditions likely through today. Wind up to ${current.windSpeed.toStringAsFixed(0)} km/h.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHourlyForecast(List<HourlyData> hourly) {
    final nextHours = hourly
        .where((item) {
          final itemTime = DateTime.parse(item.time);
          return itemTime.isAfter(
            DateTime.now().subtract(const Duration(hours: 1)),
          );
        })
        .take(8)
        .toList();

    if (nextHours.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Card(
        color: Colors.white.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Now • Hourly',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white54, height: 20, thickness: 0.5),

              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: nextHours.length,
                  itemBuilder: (context, index) {
                    final item = nextHours[index];
                    final info = getWeatherInfo(item.weatherCode);
                    final isNow = index == 0;

                    String timeLabel = isNow
                        ? 'Now'
                        : item.time.substring(11, 13);

                    return Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            timeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(
                            info['icon'] as IconData,
                            size: 30,
                            color: Colors.white,
                          ),
                          Text(
                            '${item.temperature.toStringAsFixed(0)}°',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyForecast(List<DailyData> daily) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Card(
        color: Colors.white.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '10-Day Forecast',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              const Divider(color: Colors.white54, height: 20, thickness: 0.5),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: daily.length,
                itemBuilder: (context, index) {
                  final item = daily[index];
                  final info = getWeatherInfo(2);

                  final date = DateTime.parse(item.date);
                  String dayName = index == 0
                      ? 'Today'
                      : (index == 1 ? 'Tom' : _getDayName(date.weekday));

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            dayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Icon(
                          info['icon'] as IconData,
                          size: 20,
                          color: Colors.white,
                        ),

                        const SizedBox(width: 10),
                        Text(
                          '${item.minTemp.toStringAsFixed(0)}°',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(width: 5),
                        Expanded(
                          child: _buildTemperatureBar(
                            item.minTemp,
                            item.maxTemp,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${item.maxTemp.toStringAsFixed(0)}°',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemperatureBar(double minTemp, double maxTemp) {
    final totalRange = _maxDailyTemp - _minDailyTemp;
    if (totalRange == 0) return const SizedBox.shrink();
    final minOffset = (minTemp - _minDailyTemp) / totalRange;
    final rangeWidth = (maxTemp - minTemp) / totalRange;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        final minOffsetWidth = barWidth * minOffset;
        final rangeBarWidth = barWidth * rangeWidth;

        return Container(
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: Colors.white54,
            borderRadius: BorderRadius.circular(2.5),
          ),
          child: Stack(
            children: [
              Positioned(
                left: minOffsetWidth,
                child: Container(
                  width: rangeBarWidth,
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.yellow.shade100, Colors.orange],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF8BB7FF), Color(0xFF67A0FF)],
    );

    return Container(
      decoration: const BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter city (e.g., Dhaka)',
                            hintStyle: TextStyle(
                              color: Colors.black.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // গো বাটন
                      ElevatedButton(
                        onPressed: _fetchWeather,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Go',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_currentState == WeatherState.loading)
                  const Padding(
                    padding: EdgeInsets.all(80.0),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),

                if (_currentState == WeatherState.error)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                if (_currentState == WeatherState.success &&
                    _weatherData != null)
                  Column(
                    children: [
                      _buildCurrentWeather(
                        _weatherData!.current,
                        _weatherData!.daily.first,
                      ),
                      _buildHourlyForecast(_weatherData!.hourly),

                      const SizedBox(height: 10),

                      _buildDailyForecast(_weatherData!.daily),

                      const SizedBox(height: 30),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
