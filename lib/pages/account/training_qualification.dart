import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_worker/bloc/theme_bloc.dart';
import 'package:m_worker/utils/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingQualification extends StatefulWidget {
  const TrainingQualification({super.key});

  @override
  State<TrainingQualification> createState() => _TrainingQualificationState();
}

class _TrainingQualificationState extends State<TrainingQualification> {
  final workerTrainingQualificationData = [];
  int expiredItemsCount = 0;

  @override
  void initState() {
    _fetchData();
    super.initState();
  }

  void _fetchData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final workerID = prefs.getString('workerID');
      final response =
          await Api.get('getWorkerTrainingQualificationData/$workerID');
      final Map<String, dynamic> res = response as Map<String, dynamic>;
      setState(() {
        workerTrainingQualificationData.clear();
        workerTrainingQualificationData.addAll(res['data']);
        expiredItemsCount = _calculateExpiredItemsCount();
      });
    } catch (e) {
      log('Error fetching data: $e');
    }
  }

  int _calculateExpiredItemsCount() {
    int count = 0;
    for (var item in workerTrainingQualificationData) {
      if (_isExpired(item['ExpiryDate'])) {
        count++;
      }
    }
    return count;
  }

  bool _isExpired(String expiryDate) {
    final expiry = DateTime.parse(expiryDate);
    final now = DateTime.now();
    return expiry.isBefore(now);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(color: colorScheme.onSurface),
            title: Text('Training & Qualification',
                style: TextStyle(color: colorScheme.onSurface)),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_outlined),
                    onPressed: () {
                      showGeneralDialog(context: context, pageBuilder: (context, anim1, anim2) {
                        return AlertDialog(
                          title: Text('Expired Items', style: TextStyle(color: colorScheme.error)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var item in workerTrainingQualificationData)
                                if (_isExpired(item['ExpiryDate']))
                                  ListTile(
                                    title: Text(
                                        '${item['TrainingItem']} - ${item['CredentialLevel']}'),
                                    subtitle: Text('Expiry Date: ${item['ExpiryDate']}'),
                                  ),

                              if (expiredItemsCount == 0)
                                Text('No expired items found', style: TextStyle(color: colorScheme.onSurface)),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Close', style: TextStyle(color: colorScheme.primary)),
                              ),
                            ],
                          ),
                        );
                      });
                    },
                  ),
                  if (expiredItemsCount > 0)
                    Positioned(
                      right: 11,
                      top: 11,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '$expiredItemsCount',
                          style: TextStyle(
                            color: colorScheme.onError,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              )
            ],
          ),
          body: SingleChildScrollView(
            child: RefreshIndicator(
              onRefresh: () async {
                _fetchData();
              },
              child: Column(
                children: [
                  _buildTrainingQualification(colorScheme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrainingQualification(colorScheme) {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          itemCount: workerTrainingQualificationData.length,
          itemBuilder: (context, index) {
            return _buildListTile(
                workerTrainingQualificationData, index, colorScheme);
          },
        ),
      ],
    );
  }

  Widget _buildListTile(workerTrainingQualificationData, index, colorScheme) {
    bool expired(String expiryDate) {
      final expiry = DateTime.parse(expiryDate);
      final now = DateTime.now();
      return expiry.isBefore(now);
    }

    return Card(
      margin: const EdgeInsets.all(10),
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${workerTrainingQualificationData[index]['TrainingItem']} - ${workerTrainingQualificationData[index]['CredentialLevel']} (${expired(workerTrainingQualificationData[index]['ExpiryDate']) ? 'Expired' : 'Valid'})',
              style: TextStyle(
                fontSize: 18,
                color: expired(
                    workerTrainingQualificationData[index]['ExpiryDate'])
                    ? colorScheme.error
                    : colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Date of Training: ${workerTrainingQualificationData[index]['TrainingDate']}',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            Text(
              'Review: ${workerTrainingQualificationData[index]['ReviewDate']}',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            Text(
              'Expiry Date: ${workerTrainingQualificationData[index]['ExpiryDate']}',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
