import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:s3_storage/s3_storage.dart';

class mShiftTile extends StatefulWidget {
  final String date;
  final Map<String, dynamic> shiftsForDate;
  final ColorScheme colorScheme;

  const mShiftTile(
      {super.key,
      required this.date,
      required this.shiftsForDate,
      required this.colorScheme});

  @override
  State<mShiftTile> createState() => _mShiftTileState();
}

class _mShiftTileState extends State<mShiftTile> {
  String? _pfp;

  String calculateShiftDuration(String shiftStart, String shiftEnd) {
    final start =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(shiftStart, true);
    var end = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(shiftEnd, true);

    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    final duration = end.difference(start);

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0
        ? '$hours hr ${minutes > 0 ? '$minutes min' : ''}'
        : '$minutes min';
  }

  void _getPfp(profilePhoto) async {
    try {
      final s3Storage = S3Storage(
        endPoint: 's3.ap-southeast-2.amazonaws.com',
        accessKey: dotenv.env['S3_ACCESS_KEY']!,
        secretKey: dotenv.env['S3_SECRET_KEY']!,
        region: 'ap-southeast-2',
      );

      log('########### Profile Photo: $profilePhoto');
      final url = await s3Storage.presignedGetObject(
        profilePhoto.toString().split('/').first,
        profilePhoto.toString().split('/').sublist(1).join('/'),
      );

      setState(() {
        _pfp = url;
      });
    } catch (e) {
      log('Error getting profile picture: $e');
    }
  }

  @override
  void initState() {
    _getPfp(widget.shiftsForDate['ClientProfilePhoto']);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _buildShiftCard(context, widget.shiftsForDate, widget.colorScheme);
  }

  Widget _buildShiftCard(
      context, Map<String, dynamic> shift, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/shift_details', arguments: shift);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Card(
          color: colorScheme.secondaryContainer,
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colorScheme.primary,
                    child: _pfp != null
                        ? ClipOval(
                            child: Image.network(
                              _pfp!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            '${shift['ClientFirstName'][0]}${shift['ClientLastName'][0]}',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${shift['ClientFirstName']} ${shift['ClientLastName']}',
                          style: TextStyle(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              color: colorScheme.secondary),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${shift['ServiceDescription']}',
                          style: TextStyle(
                              fontSize: 14, color: colorScheme.secondary),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Card(
                              color:
                                  colorScheme.primaryContainer.withOpacity(0.5),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '${DateFormat('hh:mm aa').format(DateTime.parse(shift['ShiftStart']).toUtc().toLocal())} - ${DateFormat('hh:mm aa').format(DateTime.parse(shift['ShiftEnd']).toUtc().toLocal())} (${calculateShiftDuration(shift['ShiftStart'], shift['ShiftEnd'])})',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
