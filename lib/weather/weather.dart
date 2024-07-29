import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class Weather {
  final String apiKey;

  late String name = '';
  late String icon = '';
  late String description = '';
  late double temp = 0.0;
  late int humidity = 0;
  late double speed = 0.0;
  late double lon = 0.0;
  late double lat = 0.0;
  late String timeString = '';

  Weather(this.apiKey);

  Future<void> fetchWeather(double latitude, double longitude) async {
    final String url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&units=metric&appid=$apiKey';
    log(url);

    try {
      final response = await http.get(Uri.parse(url));
      final Map<String, dynamic> data = json.decode(response.body);
      displayWeather(data);
    } catch (e) {
      return;
    }
  }

  void displayWeather(Map<String, dynamic> data) {
    name = data['name'];
    icon = data['weather'][0]['icon'];
    description = data['weather'][0]['description'];
    temp = data['main']['temp'];
    humidity = data['main']['humidity'];
    speed = data['wind']['speed'];
    lon = data['coord']['lon'];
    lat = data['coord']['lat'];
    timeString = '';
  }
}



