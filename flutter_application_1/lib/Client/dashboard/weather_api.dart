import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  final String apiKey = "011aca7afd2368d29055ff11afff5ed2";
  final String city = "Paris";

  Future<Map<String, dynamic>> fetchWeather() async {
    final url =
        "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch weather");
    }
  }

  /// 🔹 Check if cleaning is safe
  Future<bool> isCleaningSafe() async {
    final weather = await fetchWeather();

    final condition = (weather['weather'][0]['main'] ?? '').toString().toLowerCase();
    final windSpeed = (weather['wind']['speed'] ?? 0).toDouble(); // m/s

    // Safety rules:
    // 1. Don't clean if raining or thunderstorm
    // 2. Don't clean if wind speed > 10 m/s (~36 km/h)
    if (condition.contains('rain') || condition.contains('thunderstorm')) return false;
    if (windSpeed > 10) return false;

    return true;
  }
}
