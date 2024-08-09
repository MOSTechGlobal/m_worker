import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../bloc/theme_bloc.dart';
import 'weather.dart';

class WeatherWidget extends StatefulWidget {
  final String city;
  final String? userName;

  const WeatherWidget({super.key, required this.city, required this.userName});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final Weather weather = Weather('f820fd905393e40aec82ce97b6630c7f');

  String _temperature = '';
  String _icon = '';
  String _description = '';
  String _city = '';

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        mounted
            ? showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Location services are disabled'),
                    content: const Text(
                        'Please enable location services to continue'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await Geolocator.requestPermission();
                          fetchWeatherData();
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  );
                })
            : null;
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      mounted
          ? showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Location services are disabled'),
                  content: const Text(
                      'Please enable location services in the app settings'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await Geolocator.openAppSettings();
                        fetchWeatherData();
                      },
                      child: const Text('Open Settings'),
                    ),
                  ],
                );
              })
          : null;
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> fetchWeatherData() async {
    Position position = await _determinePosition();
    log(position.longitude);
    log(position.latitude);
    await weather.fetchWeather(position.latitude, position.longitude);

    if (mounted) {
      setState(() {
        _temperature = weather.temp.toString();
        _icon = weather.icon;
        _description = weather.description;
        _city = weather.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            color: colorScheme.secondaryContainer.withOpacity(0.5),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Greetings, ',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.secondary,
                          ),
                        ),
                        Text(
                          widget.userName!,
                          style: TextStyle(
                            fontSize: 18,
                            color: colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.refresh, color: colorScheme.primary, size: 24),
                          color: colorScheme.secondary,
                          onPressed: () {
                            fetchWeatherData();
                          },
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text(
                                  _temperature.isNotEmpty
                                      ? '${double.parse(_temperature).round()}'
                                      : '--',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.secondary,
                                  ),
                                ),
                                Text(
                                  ' ${String.fromCharCode(0x00B0)}C',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _city.isNotEmpty ? _city : '---',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Image.network(
                              _icon.isNotEmpty
                                  ? 'https://openweathermap.org/img/wn/$_icon@4x.png'
                                  : 'https://openweathermap.org/img/wn/01n@4x.png',
                              scale: 4,
                            ),
                            Text(
                              _description.isNotEmpty ? _description : '---',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
