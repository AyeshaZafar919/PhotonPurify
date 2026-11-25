// CLIENT DASHBOARD WITH WEATHER IMPACT + REALTIME DB SAFETY FLAG

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:lottie/lottie.dart';

/// 🔹 Weather Service
class WeatherService {
  final String apiKey = "011aca7afd2368d29055ff11afff5ed2";
  final String city = "Islamabad";

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
}

/// 🔹 Notification Model
class AppNotification {
  final String message;
  final DateTime timestamp;
  final bool isFault;

  AppNotification(this.message, {this.isFault = false})
      : timestamp = DateTime.now();
}

/// 🔹 Notification Manager
class NotificationManager extends ChangeNotifier {
  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => _notifications.reversed.toList();

  void add(String message, {bool isFault = false}) {
    if (_notifications.isEmpty || _notifications.last.message != message) {
      _notifications.add(AppNotification(message, isFault: isFault));
      notifyListeners();
    }
  }

  void clear() {
    _notifications.clear();
    notifyListeners();
  }
}

final notificationManager = NotificationManager();

/// 🔹 Notification Icon with Badge
class NotificationIcon extends StatelessWidget {
   final String plantId;

  const NotificationIcon({super.key, required this.plantId});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: notificationManager,
      builder: (context, _) {
        int count = notificationManager.notifications.length;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => NotificationList(plantId: plantId),
                );
              },
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "$count",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 🔹 Notification List Bottom Sheet
class NotificationList extends StatelessWidget {
   final String plantId;

  const NotificationList({super.key, required this.plantId});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));

    return Container(
      height: 500,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff0A0F1C),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [

          /// 🔹 HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Notifications",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.notifications, color: Colors.cyanAccent),
            ],
          ),

          const SizedBox(height: 16),

          /// 🔹 LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("notificationss")
                  .where("timestamp",
                      isGreaterThan: Timestamp.fromDate(last24h))
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.cyanAccent,
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No notifications in last 24 hours",
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>;

                    final isFault = data["type"] == "fault";

                    final time = data["timestamp"] != null
                        ? (data["timestamp"] as Timestamp).toDate()
                        : DateTime.now();

                    return _notificationCard(
                      message: data["message"] ?? "",
                      time: time,
                      isFault: isFault,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 MODERN CARD
  Widget _notificationCard({
    required String message,
    required DateTime time,
    required bool isFault,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFault ? Colors.redAccent : Colors.cyanAccent.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: isFault
                ? Colors.redAccent.withOpacity(0.2)
                : Colors.cyanAccent.withOpacity(0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [

          /// 🔹 ICON
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFault
                  ? Colors.redAccent.withOpacity(0.15)
                  : Colors.cyanAccent.withOpacity(0.15),
            ),
            child: Icon(
              isFault ? Icons.error_outline : Icons.notifications,
              color: isFault ? Colors.redAccent : Colors.cyanAccent,
            ),
          ),

          const SizedBox(width: 14),

          /// 🔹 TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  _formatTime(time),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 TIME FORMATTER
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hr ago";

    return "${time.day}/${time.month} ${time.hour}:${time.minute}";
  }
}

/// 🔹 Client Dashboard
class ClientDashboard extends StatefulWidget {
  final String plantId;

  const ClientDashboard({super.key, required this.plantId});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  final firestore = FirebaseFirestore.instance;
  final realtimeDB = FirebaseDatabase.instance.ref();
  final WeatherService weatherService = WeatherService();

  Map<String, double> dailyVoltages = {
  "mon": 0.0,
  "tue": 0.0,
  "wed": 0.0,
  "thu": 0.0,
  "fri": 0.0,
  "sat": 0.0,
  "sun": 0.0,
};


  String? temperature;
  String? condition;
  String? weatherImpact;
  double realtimePowerWatt = 0.0;
  double todayEnergyWh = 0.0;
  double weekEnergyWh = 0.0;
  double monthEnergyWh = 0.0;
  DateTime? lastUpdateTime;
  DateTime? lastSavedTime;
  double todayTotalVoltage = 0.0;
  double weekTotalVoltage = 0.0;
double monthTotalVoltage = 0.0;
// Track last snapshot timestamp
DateTime? lastVoltageTimestamp;
double batteryPercentage = 0.0;
double totalCleaningCycles =0;
double efficiency =0;
double todayRunHours=0;
double todayCleaningCycles = 0.0;




  bool lastCleaning = false;

  @override
  void initState() {
    super.initState();
    loadWeather();
    loadInitialEnergy().then((_) => listenSolarVoltage());
    listenBatteryVoltage(); // <<< Add this
    listenTodayCleaningCycles();
    
  }

  /// 🔹 Listen Realtime DB for Voltage & Current (corrected)
  void listenSolarVoltage() async {
  final docRef =
      firestore.collection("clients").doc(widget.plantId);

  final now = DateTime.now();
  final todayDate =
      "${now.year}-${now.month}-${now.day}";
  final currentMonth =
      "${now.year}-${now.month}";
  final currentWeek =
      "${now.year}-W${_getWeekNumber(now)}";

  // 🔹 Load existing totals FIRST
  final doc = await docRef.get();
  if (doc.exists) {
    final data = doc.data()!;

    String? savedDate = data['last_saved_date'];
    String? savedMonth = data['last_saved_month'];
    String? savedWeek = data['last_saved_week'];

    todayTotalVoltage =
        (data['today_voltage'] ?? 0).toDouble();
    weekTotalVoltage =
        (data['week_voltage'] ?? 0).toDouble();
    monthTotalVoltage =
        (data['month_voltage'] ?? 0).toDouble();

    final rawWeekly =
        Map<String, dynamic>.from(data['weekly_chart'] ?? {});
    dailyVoltages = {
      "mon": (rawWeekly['mon'] ?? 0).toDouble(),
      "tue": (rawWeekly['tue'] ?? 0).toDouble(),
      "wed": (rawWeekly['wed'] ?? 0).toDouble(),
      "thu": (rawWeekly['thu'] ?? 0).toDouble(),
      "fri": (rawWeekly['fri'] ?? 0).toDouble(),
      "sat": (rawWeekly['sat'] ?? 0).toDouble(),
      "sun": (rawWeekly['sun'] ?? 0).toDouble(),
    };

    // 🔹 Reset only if actual day changed
    if (savedDate != todayDate) {
      todayTotalVoltage = 0.0;
    }

    // 🔹 Reset only if actual week changed
    if (savedWeek != currentWeek) {
      weekTotalVoltage = 0.0;
      dailyVoltages.updateAll((key, value) => 0.0);
    }

    // 🔹 Reset only if actual month changed
    if (savedMonth != currentMonth) {
      monthTotalVoltage = 0.0;
    }
  }

  // 🔹 Start realtime listener
  realtimeDB
      .child("devices/${widget.plantId}/sensors-data")
      .onValue
      .listen((event) async {
    if (event.snapshot.value == null) return;

    final data =
        Map<String, dynamic>.from(event.snapshot.value as Map);

    double solarVoltage = 0.0;

    try {
      var solar = data['Solar'];
      if (solar is num) {
        solarVoltage = solar.toDouble();
      } else if (solar is String) {
        solarVoltage = double.tryParse(solar) ?? 0.0;
      } else if (solar is Map && solar['value'] != null) {
        solarVoltage =
            (solar['value'] as num).toDouble();
      }
    } catch (_) {}

    setState(() {
      realtimePowerWatt = solarVoltage;

      // 🔹 Accumulate
      todayTotalVoltage += solarVoltage;
      weekTotalVoltage += solarVoltage;
      monthTotalVoltage += solarVoltage;

      String dayKey = _getWeekdayKey(DateTime.now().weekday);
      dailyVoltages[dayKey] =
          (dailyVoltages[dayKey] ?? 0) + solarVoltage;
    });

    // 🔹 Save updated totals safely
    await docRef.update({
      "today_voltage": todayTotalVoltage,
      "week_voltage": weekTotalVoltage,
      "month_voltage": monthTotalVoltage,
      "weekly_chart": dailyVoltages,
      "last_saved_date": todayDate,
      "last_saved_month": currentMonth,
      "last_saved_week": currentWeek,
      "last_updated": FieldValue.serverTimestamp(),
    });
  });
}

int _getWeekNumber(DateTime date) {
  final firstDayOfYear = DateTime(date.year, 1, 1);
  final daysDifference = date.difference(firstDayOfYear).inDays;
  return ((daysDifference + firstDayOfYear.weekday) / 7).ceil();
}


// Helper function to map weekday int to string key
String _getWeekdayKey(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return "mon";
    case DateTime.tuesday:
      return "tue";
    case DateTime.wednesday:
      return "wed";
    case DateTime.thursday:
      return "thu";
    case DateTime.friday:
      return "fri";
    case DateTime.saturday:
      return "sat";
    case DateTime.sunday:
      return "sun";
    default:
      return "";
  }
}


void resetTotalsIfNeeded() {
  final now = DateTime.now();

  if (lastVoltageTimestamp == null) {
    lastVoltageTimestamp = now;
    return;
  }

  // Reset daily total if day changed
  if (lastVoltageTimestamp!.day != now.day) {
    todayTotalVoltage = 0.0;
  }

  // Reset weekly total if week changed
  if (lastVoltageTimestamp!.weekday > now.weekday) {
    weekTotalVoltage = 0.0;
  }

  // Reset monthly total if month changed
  if (lastVoltageTimestamp!.month != now.month) {
    monthTotalVoltage = 0.0;
  }

  lastVoltageTimestamp = now;
}

double parseBattery(dynamic battery) {
  if (battery == null) return 0.0;

  if (battery is num) return battery.toDouble();
  if (battery is String) return double.tryParse(battery) ?? 0.0;
  if (battery is Map) {
    // Try to read nested 'value'
    var val = battery['value'];
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
  }

  return 0.0; // fallback
}


void listenBatteryVoltage() {
  realtimeDB
      .child("devices/${widget.plantId}/sensors-data/Battery")
      .onValue
      .listen((event) {

    if (event.snapshot.value == null) return;

    // ✅ SAFE parsing (handles String, num, Map)
    double batteryVoltage = parseBattery(event.snapshot.value);

    // Convert to percentage
    setState(() {
      batteryPercentage =
          ((batteryVoltage / 12.0) * 100).clamp(0, 100);
    });

    print("Battery voltage: $batteryVoltage, percentage: $batteryPercentage");
  });
}


  /// 🔹 Load stored energy
  Future<void> loadInitialEnergy() async {
    final doc = await firestore.collection("clients").doc(widget.plantId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        todayEnergyWh = (data['today_Wh'] ?? 0).toDouble();
        weekEnergyWh = (data['week_Wh'] ?? 0).toDouble();
        monthEnergyWh = (data['month_Wh'] ?? 0).toDouble();

        final rawWeekly = Map<String, dynamic>.from(data['weekly_chart'] ?? {});
        /*weeklyEnergy = {
          "mon": (rawWeekly['mon'] ?? 0).toDouble(),
          "tue": (rawWeekly['tue'] ?? 0).toDouble(),
          "wed": (rawWeekly['wed'] ?? 0).toDouble(),
          "thu": (rawWeekly['thu'] ?? 0).toDouble(),
          "fri": (rawWeekly['fri'] ?? 0).toDouble(),
          "sat": (rawWeekly['sat'] ?? 0).toDouble(),
          "sun": (rawWeekly['sun'] ?? 0).toDouble(),
        };*/
      });
    }
  }

  /// 🔹 Update Cleaning Safety Flag in Realtime DB
  Future<void> updateCleaningSafety(bool flag) async {
    await realtimeDB
        .child("devices/${widget.plantId}/controls/cleaning_safety_flag")
        .set(flag);
  }

  /// 🔹 Load weather & determine safety
  void loadWeather() async {
    try {
      var data = await weatherService.fetchWeather();

      double windSpeed = (data["wind"]["speed"] ?? 0).toDouble();
      String weather = data['weather'][0]['main'];

      bool isRain = weather.toLowerCase().contains("rain");
      bool isStorm = weather.toLowerCase().contains("thunder");
      bool isSnow = weather.toLowerCase().contains("snow");
      bool highWind = windSpeed > 10; // >10 m/s

      bool safetyFlag = isRain || isStorm || isSnow || highWind;

      await updateCleaningSafety(safetyFlag);

      setState(() {
        temperature = (data['main']['temp'] as num).toStringAsFixed(0);
        condition = weather;

        if (safetyFlag) {
          if (isRain) {
            weatherImpact = "Rain expected — cleaning is paused.";
          } else if (isStorm) {
            weatherImpact = "Thunderstorm — cleaning blocked.";
          } else if (isSnow) {
            weatherImpact = "Snowfall detected — cleaning unsafe.";
          } else if (highWind) {
            weatherImpact = "High winds — cleaning disabled for safety.";
          }
        } else {
          weatherImpact = "Weather is clear — cleaning is allowed.";
        }
      });
    } catch (e) {
      print("Weather error: $e");
    }
  }

  IconData getWeatherIcon(String? condition) {
    switch (condition?.toLowerCase()) {
      case "clear":
        return Icons.wb_sunny;
      case "clouds":
        return Icons.cloud;
      case "rain":
        return Icons.umbrella;
      case "thunderstorm":
        return Icons.flash_on;
      case "snow":
        return Icons.ac_unit;
      default:
        return Icons.wb_cloudy;
    }
  }

  /// 🔹 Check alerts
  void checkAlerts(Map<String, dynamic> data) {
    var batteryLevel = (data['battery_level'] ?? 0).toDouble();
    var waterLevel = (data['water_level'] ?? 0).toDouble();
    var isCleaning = data['isCleaning'] ?? false;
    var output = (data['output_power_kw'] ?? 0).toDouble();

    if (batteryLevel < 20) {
      notificationManager.add("⚠️ Battery Low: $batteryLevel%", isFault: true);
    }
    if (waterLevel < 20) {
      notificationManager.add("⚠️ Water Low: $waterLevel%", isFault: true);
    }
    if (output < 0.9) {
      notificationManager.add("⚡ Low Output Power: $output kW", isFault: true);
    }
    if (isCleaning != lastCleaning) {
      if (isCleaning) {
        notificationManager.add("✅ Cleaning started");
      } else {
        notificationManager.add("🧹 Cleaning stopped");
      }
      lastCleaning = isCleaning;
    }
  }


void listenTodayCleaningCycles() {
  FirebaseDatabase.instance
      .ref(
        "devices/${widget.plantId}/sensors-data/today_cleaning_cycles",
      )
      .onValue
      .listen((event) {
    final data = event.snapshot.value;

    print("today_cleaning_cycles = $data");

    double newValue = 0;

    if (data != null) {
      newValue = double.parse(data.toString());
    }

    if (mounted) {
      setState(() {
        todayCleaningCycles = newValue;
      });
    }
  });
}

  /// 🔹 UI
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xff0A0F1C),
    appBar: AppBar(
  backgroundColor: Colors.transparent,
  elevation: 0,
  title: Text(
    'Photon Purify',
    style: GoogleFonts.poppins(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 22,
    ),
  ),
  centerTitle: true,

  actions: [
    NotificationIcon(plantId: widget.plantId),

    IconButton(
      icon: const Icon(
        Icons.logout,
        color: Colors.white,
      ),
      tooltip: "Logout",
      onPressed: () async {
        await FirebaseAuth.instance.signOut();

        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      },
    ),
  ],
),
    body: StreamBuilder<DocumentSnapshot>(
      stream: firestore.collection("clients").doc(widget.plantId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        checkAlerts(data);

        final days = ["mon","tue","wed","thu","fri","sat","sun"];
        List<FlSpot> spots = List.generate(
          days.length,
          (i) => FlSpot(i.toDouble(), dailyVoltages[days[i]] ?? 0.0),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              // HEADER
              FadeInDown(child: _header()),
              const SizedBox(height: 20),

              // MAIN ENERGY CARD
              ZoomIn(child: _mainCard()),
              const SizedBox(height: 20),

              // STATS
              FadeInUp(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _batteryRing2(),
                    _miniStat2("OUTPUT", "${realtimePowerWatt.toStringAsFixed(1)}V", Icons.flash_on),
                    _miniStat2("STATUS", data['battery_status'] ?? "OK", Icons.check_circle),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              FadeInUp(child: _weatherCard()),

              const SizedBox(height: 20),

              FadeInUp(child: _chart(spots)),
            ],
          ),
        );
      },
    ),
  );
}

  /// UI helpers
  Widget _infoCard(String title, String value, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 100,
        height: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _monitorCard(IconData icon, String title, String value, Color color) {
  return Card(
    color: color,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
Widget _premiumHeader() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Welcome Back",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Solar Dashboard",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),

      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          "${temperature ?? '--'}°C",
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    ],
  );
}

Widget _weatherGlass() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white12),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(child: Text(weatherImpact ?? 'Loading weather...', style: const TextStyle(color: Colors.white))),
      ],
    ),
  );
}

Widget _chartCard(List<FlSpot> spots) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xff162033),
      borderRadius: BorderRadius.circular(24),
    ),
    child: SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 6,
          minY: 0,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 4,
              color: Colors.cyanAccent,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: true),
            )
          ],
        ),
      ),
    ),
  );
}
Widget _mainEnergyCard() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        colors: [
          Color(0xff00C6FF),
          Color(0xff0072FF),
        ],
      ),
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      children: [
        const Text(
          "TODAY VOLTAGE",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          "${todayTotalVoltage.toStringAsFixed(1)} V",
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          "Current: ${realtimePowerWatt.toStringAsFixed(1)} V",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ],
    ),
  );
}
Widget _batteryRing() {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xff162033),
      borderRadius: BorderRadius.circular(18),
    ),
    child: CircularPercentIndicator(
      radius: 42,
      lineWidth: 8,
      animation: true,
      animateFromLastPercent: true,
      percent: (batteryPercentage / 100).clamp(0.0, 1.0),
      center: Text(
        "${batteryPercentage.toInt()}%",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      progressColor: Colors.greenAccent,
      backgroundColor: Colors.white12,
      circularStrokeCap: CircularStrokeCap.round,
    ),
  );
}
Widget _miniStat(String title, String value, IconData icon) {
  return Container(
    width: 95,
    height: 95,
    decoration: BoxDecoration(
      color: const Color(0xff162033),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 26),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}
Widget _header() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome Back', style: GoogleFonts.poppins(color: Colors.white70)),
          Text('Solar Dashboard', style: GoogleFonts.poppins(color: Colors.white,fontSize: 22,fontWeight: FontWeight.bold)),
        ],
      ),
      Text("${temperature ?? '--'}°C",
          style: const TextStyle(color: Colors.cyanAccent, fontSize: 18)),
    ],
  );
}
double maxVoltage = 30.0; // panel max voltage
Widget _mainCard() {
  // ===== Calculations =====
  double efficiency =
      (realtimePowerWatt / maxVoltage) * 100;

  efficiency = efficiency.clamp(0, 100);

  return Container(
    width: double.infinity, // ✅ Full width
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xff00C6FF),
          Color(0xff0072FF),
        ],
      ),
      boxShadow: const [
        BoxShadow(
          color: Colors.black45,
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// HEADER
        Row(
          children: const [
            Icon(Icons.bolt, color: Colors.white, size: 26),
            SizedBox(width: 10),
            Text(
              "TODAY PERFORMANCE",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        /// MAIN VALUE
        /// REPLACE your current main value section with this:

Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [

    /// LEFT SIDE MAIN VALUE
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedFlipCounter(
          value: todayTotalVoltage,
          suffix: " V",
          textStyle: const TextStyle(
            fontSize: 34,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          "Today's Energy Output",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ],
    ),

    /// RIGHT SIDE LIVE BLINKING CIRCLE
    _liveVoltagePulse(),
  ],
),

        const SizedBox(height: 8),

        Text(
          "Live Voltage: ${realtimePowerWatt.toStringAsFixed(1)} V",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 22),

        /// STATS GRID
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            _miniInfo(
              Icons.cleaning_services,
              "Cycles Today",
              todayCleaningCycles.toInt().toString(),
            ),

            
            _miniInfo(
              Icons.speed,
              "Efficiency",
              "${efficiency.toStringAsFixed(1)}%",
            ),

            _miniInfo(
              Icons.access_time,
              "Run Time",
              "${todayRunHours.toStringAsFixed(1)}h",
            ),
          ],
        ),

        const SizedBox(height: 18),

        /// FOOTER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Updated just now",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "LIVE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// MINI INFO TILE
Widget _miniInfo(IconData icon, String title, String value) {
  return Expanded(
    child: Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}
Widget _batteryRing2() {
  return CircularPercentIndicator(
    radius: 40,
    lineWidth: 8,
    percent: (batteryPercentage / 100).clamp(0.0, 1.0),
    center: Text("${batteryPercentage.toInt()}%",
        style: const TextStyle(color: Colors.white)),
    progressColor: Colors.greenAccent,
    backgroundColor: Colors.white10,
    animation: true,
  );
}
Widget _miniStat2(String title, String value, IconData icon) {
  return Container(
    width: 95,
    height: 95,
    decoration: BoxDecoration(
      color: const Color(0xff141C2B),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.cyanAccent),
        Text(value, style: const TextStyle(color: Colors.white)),
        Text(title, style: const TextStyle(color: Colors.white54)),
      ],
    ),
  );
}
Widget _weatherCard() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(
          child: Text(weatherImpact ?? "Loading...",
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
Widget _chart(List<FlSpot> spots) {
  return Container(
    height: 240,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xff141C2B),
      borderRadius: BorderRadius.circular(20),
    ),
    child: LineChart(
      LineChartData(
        minX: 0,
        maxX: 6,
        minY: 0,

        // Auto max Y based on values
        maxY: spots.isEmpty
            ? 10
            : spots
                    .map((e) => e.y)
                    .reduce((a, b) => a > b ? a : b) +
                50,

        // ===== GRID =====
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 50,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white10,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.white10,
              strokeWidth: 1,
            );
          },
        ),

        borderData: FlBorderData(show: false),

        // ===== AXIS TITLES =====
        titlesData: FlTitlesData(
          // Bottom = Week Days
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                const days = [
                  "Mon",
                  "Tue",
                  "Wed",
                  "Thu",
                  "Fri",
                  "Sat",
                  "Sun"
                ];

                int index = value.toInt();

                if (index >= 0 && index < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      days[index],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
          ),

          // Left = Values
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),

          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),

        // ===== LINE DATA =====
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.cyanAccent,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.cyanAccent.withOpacity(0.18),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _liveVoltagePulse() {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.6, end: 1.0),
    duration: const Duration(milliseconds: 900),
    curve: Curves.easeInOut,
    builder: (context, value, child) {
      return Container(
        width: 85,
        height: 85,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.08),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(value * 0.8),
              blurRadius: 18 * value,
              spreadRadius: 4 * value,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.bolt,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(height: 2),
                Text(
                  realtimePowerWatt.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "LIVE",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    onEnd: () {
      if (mounted) {
        setState(() {});
      }
    },
  );
}

Widget _miniEfficiencyCard() {
  double maxVoltage = 30.0;

  double efficiency =
      (realtimePowerWatt / maxVoltage) * 100;

  efficiency = efficiency.clamp(0, 100);

  Color color =
      efficiency > 80
          ? Colors.greenAccent
          : efficiency > 50
              ? Colors.orangeAccent
              : Colors.redAccent;

  return Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bolt, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          "${efficiency.toStringAsFixed(0)}%",
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    ),
  );
}

}