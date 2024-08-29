// create a class to handle the shared preferences
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static Future<SharedPreferences> getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // for email
  static Future<String?> getEmail() async {
    final prefs = await getPrefs();
    return prefs.getString('email');
  }

  static Future<void> setEmail(String email) async {
    final prefs = await getPrefs();
    prefs.setString('email', email);
  }

  static Future<void> clearEmail() async {
    final prefs = await getPrefs();
    prefs.remove('email');
  }

  // for password
  static Future<String?> getPassword() async {
    final prefs = await getPrefs();
    return prefs.getString('password');
  }

  static Future<void> setPassword(String password) async {
    final prefs = await getPrefs();
    prefs.setString('password', password);
  }

  static Future<void> clearPassword() async {
    final prefs = await getPrefs();
    prefs.remove('password');
  }

  // for token
  static Future<String?> getToken() async {
    final prefs = await getPrefs();
    return prefs.getString('bearer');
  }

  static Future<void> setToken(String token) async {
    final prefs = await getPrefs();
    prefs.setString('bearer', token);
  }

  static Future<void> clearToken() async {
    final prefs = await getPrefs();
    prefs.remove('bearer');
  }

  // for worker id
  static Future<int?> getWorkerID() async {
    final prefs = await getPrefs();
    return prefs.getInt('workerID');
  }

  static Future<void> setWorkerID(int workerID) async {
    final prefs = await getPrefs();
    prefs.setInt('workerID', workerID);
  }

  static Future<void> clearWorkerID() async {
    final prefs = await getPrefs();
    prefs.remove('workerID');
  }

  // for company name
  static Future<String?> getCompanyName() async {
    final prefs = await getPrefs();
    return prefs.getString('company');
  }

  static Future<void> setCompanyName(String company) async {
    final prefs = await getPrefs();
    prefs.setString('company', company);
  }

  static Future<void> clearCompanyName() async {
    final prefs = await getPrefs();
    prefs.remove('company');
  }

  // biometricsEnabled
  static Future<bool> getBiometricsEnabled() async {
    final prefs = await getPrefs();
    return prefs.getBool('biometricsEnabled') ?? false;
  }

  static Future<void> setBiometricsEnabled(bool enabled) async {
    final prefs = await getPrefs();
    prefs.setBool('biometricsEnabled', enabled);
  }

  static Future<void> clearBiometricsEnabled() async {
    final prefs = await getPrefs();
    prefs.remove('biometricsEnabled');
  }

  // showWeather
  static Future<bool> getShowWeather() async {
    final prefs = await getPrefs();
    return prefs.getBool('showWeather') ?? false;
  }

  static Future<void> setShowWeather(bool show) async {
    final prefs = await getPrefs();
    prefs.setBool('showWeather', show);
  }

  static Future<void> clearShowWeather() async {
    final prefs = await getPrefs();
    prefs.remove('showWeather');
  }

  // alarmSubscribed
  static Future<bool> getAlarmSubscribed() async {
    final prefs = await getPrefs();
    return prefs.getBool('alarmSubscribed') ?? false;
  }

  static Future<void> setAlarmSubscribed(bool subscribed) async {
    final prefs = await getPrefs();
    prefs.setBool('alarmSubscribed', subscribed);
  }

  static Future<void> clearAlarmSubscribed() async {
    final prefs = await getPrefs();
    prefs.remove('alarmSubscribed');
  }

  // clear all
  static Future<void> clearAll() async {
    final prefs = await getPrefs();
    prefs.clear();
  }
}
