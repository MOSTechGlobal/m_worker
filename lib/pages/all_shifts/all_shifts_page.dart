import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:m_worker/pages/all_shifts/all_shift_details/all_shifts_details_page.dart';
import 'package:m_worker/pages/shift/shift_root.dart';
import 'package:m_worker/utils/prefs.dart';

import '../../bloc/theme_bloc.dart';
import '../../utils/api.dart';

class AllShiftPage extends StatefulWidget {
  const AllShiftPage({super.key});

  @override
  State<AllShiftPage> createState() => _AllShiftPageState();
}

class _AllShiftPageState extends State<AllShiftPage> {
  List<Map<String, dynamic>> _allShifts = [];
  List<Map<String, dynamic>> _filteredShifts = [];
  List<Map<String, dynamic>> _locationShifts = [];
  List<Map<String, dynamic>> _filteredLocationShifts = [];
  List<Map<String, dynamic>> selectedShiftIDs = [];
  List<Map<String, dynamic>> clients = [];
  List<Map<String, dynamic>> shiftWorkers = [];
  String? errorMessage;
  bool isLoading = true;
  String clientID = '';
  String selectedSegment = 'StandardShifts';
  String? _pfp;

  DateTime _selectedDateFrom =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedDateTo = DateTime.now().add(const Duration(days: 30));

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

  // void _getPfp(profilePhoto) async {
  //   try {
  //     final s3Storage = S3Storage(
  //       endPoint: 's3.ap-southeast-2.amazonaws.com',
  //       accessKey: dotenv.env['S3_ACCESS_KEY']!,
  //       secretKey: dotenv.env['S3_SECRET_KEY']!,
  //       region: 'ap-southeast-2',
  //     );
  //
  //     log('########### Profile Photo: $profilePhoto');
  //     final url = await s3Storage.presignedGetObject(
  //       profilePhoto.toString().split('/').first,
  //       profilePhoto.toString().split('/').sublist(1).join('/'),
  //     );
  //
  //     setState(() {
  //       _pfp = url;
  //     });
  //   } catch (e) {
  //     log('Error getting profile picture: $e');
  //   }
  // }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
    });
    await _fetchClients();
    await _fetchShiftWorkers();
    if (selectedSegment == 'StandardShifts') {
      await _fetchPAShifts();
    } else if (selectedSegment == 'LocationShifts') {
      await _fetchLocationShifts();
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchClients() async {
    try {
      final clientsData = await Api.get('getClientMasterDataAll');
      clients = List<Map<String, dynamic>>.from(clientsData['data']);
    } catch (e) {
      log('Error fetching clients data: $e');
    }
  }

  Future<void> _fetchShiftWorkers() async {
    try {
      final shiftWorkersData = await Api.get('getWorkerMasterDataAll');
      shiftWorkers = List<Map<String, dynamic>>.from(shiftWorkersData['data']);
    } catch (e) {
      log('Error fetching shift workers data: $e');
    }
  }

  Future<void> _fetchPAShifts() async {
    try {
      final workerID = await Prefs.getWorkerID();
      log("workerID: $workerID");
      final pendingApprovalShifts =
          await Api.get('getApprovedShiftsByWorkerID/$workerID');
      log("shifts: $pendingApprovalShifts");

      if (pendingApprovalShifts['success'] == true &&
          pendingApprovalShifts['data'] is List) {
        if (pendingApprovalShifts['data'].isEmpty) {
          setState(() {
            errorMessage = 'No pending approval shifts found';
            _allShifts = [];
            _filteredShifts = [];
          });
          return;
        }
        errorMessage = null;
        setState(() {
          clientID = '${pendingApprovalShifts['data'][0]['ClientID']}';
          _allShifts =
              List<Map<String, dynamic>>.from(pendingApprovalShifts['data']);
          _filterShifts(''); // Initialize the filtered shifts with no query
        });
      } else {
        throw Exception('Invalid API response format');
      }

      if (_filteredShifts.isEmpty) {
        setState(() {
          errorMessage = 'No pending approval shifts found';
        });
      }
    } catch (e) {
      log('Error fetching roster data: $e');
      setState(() {
        errorMessage = 'Failed to fetch shifts';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchLocationShifts() async {
    final workerID = await Prefs.getWorkerID();
    log("$workerID");
    final response =
        await Api.get('getLocRosterShiftMainDataByWorkerID/$workerID');

    if (response['success'] == true && response['data'] is List) {
      if (response['data'].isEmpty) {
        setState(() {
          errorMessage = 'No pending location shifts found';
          _locationShifts = [];
          _filteredLocationShifts = [];
        });
        return;
      }
      log("loc $_locationShifts");
      errorMessage = null;
      setState(() {
        _locationShifts = List<Map<String, dynamic>>.from(response['data']);
        _filterLocationShifts(
            ''); // Initialize the filtered shifts with no query
      });
    } else {
      throw Exception('Invalid API response format');
    }

    if (_filteredLocationShifts.isEmpty) {
      setState(() {
        errorMessage = 'No pending location shifts found';
      });
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _filterShifts(String query) {
    setState(() {
      _filteredShifts = _allShifts.where((shift) {
        final shiftStart = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
            .parse(shift['ShiftStart'], true);
        final isWithinDateRange = shiftStart.isAfter(_selectedDateFrom) &&
            shiftStart.isBefore(_selectedDateTo);

        final matchesQuery = shift.values.any((value) {
          return value.toString().toLowerCase().contains(query.toLowerCase());
        });

        return isWithinDateRange && matchesQuery;
      }).toList();
    });
  }

  void _filterLocationShifts(String query) {
    setState(() {
      _filteredLocationShifts = _locationShifts.where((shift) {
        final shiftStart = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
            .parse(shift['ShiftStart'], true);
        final isWithinDateRange = shiftStart.isAfter(_selectedDateFrom) &&
            shiftStart.isBefore(_selectedDateTo);

        final matchesQuery = shift.values.any((value) {
          return value.toString().toLowerCase().contains(query.toLowerCase());
        });

        return true;
      }).toList();
    });
  }

  String? _getFormattedDateRange() {
    final formatter = DateFormat('dd MMM yyyy'); // Format: DD Month YYYY
    return '${formatter.format(_selectedDateFrom)} - ${formatter.format(_selectedDateTo)}';
  }

  // todo notify worker
  // Future<void> _sendNotification(List shiftId) async {
  //   for (var shift in shiftId) {
  //     try {
  //       // get the supportWorker1 from the filtered shifts via the shiftID
  //       final approvedShiftData = selectedSegment == 'StandardShifts'
  //           ? _filteredShifts
  //               .firstWhere((element) => element['ShiftID'] == shift['ShiftID'])
  //           : _filteredLocationShifts.firstWhere(
  //               (element) => element['ShiftID'] == shift['ShiftID']);
  //       final response = await Api.post('sendShiftNotification', {
  //         "to": "wk-cl-tl-rm",
  //         'shiftId': shift['ShiftID'].toString(),
  //         "action": "approve-reject",
  //       });
  //
  //       if (response['success'] == true) {
  //         log('Notification sent successfully');
  //         SnackBar snackBar = const SnackBar(
  //           content: Text('Notification sent successfully'),
  //           duration: Duration(seconds: 3),
  //         );
  //         ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //       } else {
  //         throw Exception('Failed to send notification');
  //       }
  //     } catch (e) {
  //       log('Error sending notification: $e');
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    // final today = DateTime.now().toUtc();

    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            scrolledUnderElevation: 0.0,
            iconTheme: IconThemeData(color: colorScheme.primary),
            backgroundColor: colorScheme.surface,
            title: Row(
              children: [
                Hero(
                  tag: 'All Shifts',
                  child: Icon(Icons.approval, color: colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  'All Shifts',
                  style: TextStyle(color: colorScheme.primary, fontSize: 18),
                ),
              ],
            ),
          ),
          body: AnimatedOpacity(
            opacity: isLoading ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                    width: 150,
                    child: LinearProgressIndicator(),
                  ))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _showDatePickerModal(context),
                              child: Card(
                                color: colorScheme.secondaryContainer,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Text(
                                    _getFormattedDateRange() ??
                                        'Select Date Range',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: IntrinsicWidth(
                              child: SegmentedButton<String>(
                                emptySelectionAllowed: false,
                                style: ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                  enableFeedback: true,
                                  foregroundColor:
                                      WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                                      if (states
                                          .contains(WidgetState.disabled)) {
                                        return colorScheme.secondary;
                                      }
                                      return colorScheme.secondary;
                                    },
                                  ),
                                  animationDuration:
                                      const Duration(milliseconds: 300),
                                ),
                                segments: const <ButtonSegment<String>>[
                                  ButtonSegment<String>(
                                      value: 'StandardShifts',
                                      label: Text('Standard Shifts')),
                                  ButtonSegment<String>(
                                      value: 'LocationShifts',
                                      label: Text('Location Shifts')),
                                ],
                                selected: {selectedSegment},
                                onSelectionChanged: (Set<String> newSelection) {
                                  setState(() {
                                    selectedSegment = newSelection.first;
                                    isLoading = true;
                                  });
                                  if (selectedSegment == 'StandardShifts') {
                                    _fetchPAShifts().then((_) {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    });
                                  } else if (selectedSegment ==
                                      'LocationShifts') {
                                    _fetchLocationShifts().then((_) {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    });
                                  }
                                },
                                showSelectedIcon: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                      errorMessage != null
                          ? Center(
                              child: Text(errorMessage!,
                                  style: TextStyle(color: colorScheme.primary)))
                          : Expanded(
                              child: selectedSegment == 'StandardShifts'
                                  ? _buildStandardShifts()
                                  : selectedSegment == 'LocationShifts'
                                      ? _buildLocationShifts()
                                      : Container(),
                            ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildStandardShifts() {
    final today = DateTime.now().toUtc();

    final futureShifts = _filteredShifts.where((shift) {
      final shiftStart = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
          .parse(shift['ShiftStart'], true);
      return shiftStart.isAfter(today) || isSameDay(shiftStart, today);
    }).toList();

    final groupedShifts = groupBy(futureShifts, (shift) {
      final shiftStart = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
          .parse(shift['ShiftStart'], true);
      return DateFormat('yyyy-MM-dd').format(shiftStart);
    });

    // Sort dates in ascending order and as per time
    final sortedDates = groupedShifts.keys.toList()
      ..sort((a, b) {
        final dateA = DateTime.parse(a);
        final dateB = DateTime.parse(b);
        return dateA.compareTo(dateB);
      });

    return RefreshIndicator(
      onRefresh: _fetchPAShifts,
      child: ListView.builder(
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final shiftsForDate = groupedShifts[date]!;
          return AnimatedOpacity(
            opacity: isLoading ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                    width: 150,
                    child: LinearProgressIndicator(),
                  ))
                : _buildDateSection(
                    date, shiftsForDate, Theme.of(context).colorScheme),
          );
        },
      ),
    );
  }

  Widget _buildLocationShifts() {
    final today = DateTime.now().toUtc();

    final futureShifts = _filteredLocationShifts.where((shift) {
      final shiftStart = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
          .parse(shift['ShiftStart'], true);
      return shiftStart.isAfter(today) || isSameDay(shiftStart, today);
    }).toList();

    final groupedShifts = groupBy(futureShifts, (shift) {
      final shiftStart = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
          .parse(shift['ShiftStart'], true);
      return DateFormat('yyyy-MM-dd').format(shiftStart);
    });

    // Sort dates in ascending order and as per time
    final sortedDates = groupedShifts.keys.toList()
      ..sort((a, b) {
        final dateA = DateTime.parse(a);
        final dateB = DateTime.parse(b);
        return dateA.compareTo(dateB);
      });

    return RefreshIndicator(
      onRefresh: _fetchLocationShifts,
      child: ListView.builder(
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final shiftsForDate = groupedShifts[date]!;
          return AnimatedOpacity(
            opacity: isLoading ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                    width: 150,
                    child: LinearProgressIndicator(),
                  ))
                : _buildDateSectionForLocationShifts(
                    date, shiftsForDate, Theme.of(context).colorScheme),
          );
        },
      ),
    );
  }

  Widget _buildDateSection(
      String date, List shiftsForDate, ColorScheme colorScheme) {
    final weekday = DateFormat('EEEE').format(DateTime.parse(date));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '$weekday, ${DateFormat('d MMMM').format(DateTime.parse(date))}',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.tertiary.withOpacity(0.7)),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shiftsForDate.length,
          itemBuilder: (context, shiftIndex) {
            final shift = shiftsForDate[shiftIndex];
            return _buildShiftCard(shift, colorScheme);
          },
        ),
      ],
    );
  }

  Widget _buildDateSectionForLocationShifts(
      String date, List shiftsForDate, ColorScheme colorScheme) {
    final weekday = DateFormat('EEEE').format(DateTime.parse(date));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '$weekday, ${DateFormat('d MMMM').format(DateTime.parse(date))}',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.tertiary.withOpacity(0.7)),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shiftsForDate.length,
          itemBuilder: (context, shiftIndex) {
            final shift = shiftsForDate[shiftIndex];
            return _buildShiftCard(shift, colorScheme);
          },
        ),
      ],
    );
  }

  Widget _buildShiftCard(Map<String, dynamic> shift, ColorScheme colorScheme) {
    bool isSelected = shift['isSelected'] ?? false;

    // Determine the display name based on the selected segment
    String displayName = selectedSegment == 'LocationShifts'
        ? (shift['LocationDescription'] ??
            'Unknown Location') // Fallback if locationName is null
        : '${shift['ClientFirstName']} ${shift['ClientLastName']}';

    String logo = selectedSegment == 'LocationShifts'
        ? (shift['LocationDescription'] ??
            '${shift['LocationDescription'][0]}') // Fallback if locationName is null
        : '${shift['ClientFirstName'][0]} ${shift['ClientLastName'][0]}';

    bool isLoc = selectedSegment == 'LocationShifts'
        ? true
        : false;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AllShiftsDetailsPage(isLoc: isLoc, shiftID: shift['ShiftID'],),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Stack(
          children: [
            Positioned(
              child: isSelected
                  ? Icon(Icons.check_circle,
                      color: colorScheme.primary, size: 25)
                  : Container(),
            ),
            Card(
              elevation: 0,
              color: isSelected
                  ? colorScheme.tertiary
                      .withOpacity(0.2) // Light background color for selected
                  : colorScheme.secondaryContainer,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                              logo,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimary),
                            ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            // Use the conditional display name here
                            style: TextStyle(
                                fontSize: 18,
                                fontStyle: FontStyle.italic,
                                color: colorScheme.secondary),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${shift['ServiceDescription']}',
                            maxLines: 2, // Limits the text to 2 lines
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14, color: colorScheme.secondary),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Card(
                                color: colorScheme.primaryContainer
                                    .withOpacity(0.5),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDatePickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, innerSetState) {
            final colorScheme = Theme.of(context).colorScheme;
            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Select Date Range',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDatePicker(context, _selectedDateFrom, (date) {
                          innerSetState(() {
                            _selectedDateFrom = date;
                          });
                          // Update the main widget state to reflect date changes
                          setState(() {});
                        }, 'From'),
                        _buildDatePicker(context, _selectedDateTo, (date) {
                          innerSetState(() {
                            _selectedDateTo = date;
                          });
                          // Update the main widget state to reflect date changes
                          setState(() {});
                        }, 'To'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        if (selectedSegment == 'StandardShifts') {
                          _filterShifts('');
                        } else if (selectedSegment == 'LocationShifts') {
                          _filterLocationShifts('');
                        }
                        Navigator.pop(context);
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                            colorScheme.secondaryContainer),
                      ),
                      child: Text('Search',
                          style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.secondary),
                          textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    DateTime initialDate,
    Function(DateTime) onDateChanged,
    String label,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: initialDate,
            onDateTimeChanged: onDateChanged,
          ),
        ),
      ],
    );
  }
}
