import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_worker/pages/all_shifts/all_shift_details/sub_pages/shift_profile_details/profile_details.dart';

import '../../../../../bloc/theme_bloc.dart';
import '../../../../../utils/api.dart';

class ShiftProfileDetailsPage extends StatefulWidget {
  final Map<dynamic, dynamic> shift;

  const ShiftProfileDetailsPage({super.key, required this.shift});

  @override
  State<ShiftProfileDetailsPage> createState() =>
      _ShiftProfileDetailsPageState();
}

class _ShiftProfileDetailsPageState extends State<ShiftProfileDetailsPage> {
  List<Map<String, dynamic>> clients = [];
  List<Map<String, dynamic>> displayedClients = [];
  List<Map<String, dynamic>> workers = [];
  List<Map<String, dynamic>> displayedWorkers = [];
  bool _isLoading = true;

  Future<void> _fetchClientMasterData() async {
    final clientIDs = widget.shift['ClientIds'];
    log("clientIDs $clientIDs");

    final responseData =
        await Api.post('getClientDataFromList', {"ids": clientIDs});

    if (responseData != null &&
        responseData['success'] &&
        responseData['data'] != null) {
      setState(() {
        clients = List<Map<String, dynamic>>.from(responseData['data']);
        displayedClients =
            List<Map<String, dynamic>>.from(responseData['data']);
      });
      log("displayedClients $displayedClients");
      _isLoading = false;
    } else {
      // Handle API errors
      log('API Error: ${responseData?['error'] ?? 'Unknown error'}');
    }
  }

  Future<void> _fetchWorkerMasterData() async {
    final workerIDs = widget.shift['WorkerIds'];
    log("workerIDs $workerIDs");

    final responseData =
        await Api.post('getClientDataFromList', {"ids": workerIDs});

    if (responseData != null &&
        responseData['success'] &&
        responseData['data'] != null) {
      setState(() {
        workers = List<Map<String, dynamic>>.from(responseData['data']);
        displayedWorkers =
            List<Map<String, dynamic>>.from(responseData['data']);
      });
      log("displayedWorkers $displayedWorkers");
      _isLoading = false;
    } else {
      // Handle API errors
      log('API Error: ${responseData?['error'] ?? 'Unknown error'}');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWorkerMasterData();
    _fetchClientMasterData();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(builder: (context, state) {
      final colorScheme = Theme.of(context).colorScheme;
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text(
                'Clients and Workers',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          backgroundColor: colorScheme.surface,
          iconTheme: IconThemeData(color: colorScheme.primary),
        ),
        backgroundColor: colorScheme.surface,
        body: AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: _isLoading ? 0.5 : 1,
          child: _isLoading
              ? const Center(
                  child: SizedBox(
                  width: 150,
                  child: LinearProgressIndicator(),
                ))
              : RefreshIndicator(
                  onRefresh: () async {
                    await _fetchClientMasterData();
                    await _fetchWorkerMasterData();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          displayedClients.isNotEmpty
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Clients",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(height: 15),
                                    ListView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: displayedClients.length,
                                      itemBuilder: (context, index) {
                                        final client = displayedClients[index];
                                        return MListTile(
                                          title:
                                              "${client['FirstName']} ${client['LastName']}",
                                          onTap: () {
                                            log("clients : $client");
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ProfileDetails(
                                                        shiftData: client,
                                                        isClient: true),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                )
                              : Container(),
                          displayedWorkers.isNotEmpty
                              ? Column(
                                  children: [
                                    Text(
                                      "Workers",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(height: 15),
                                    // Workers Section
                                    ListView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: displayedWorkers.length,
                                      itemBuilder: (context, index) {
                                        final worker = displayedWorkers[index];
                                        return MListTile(
                                          title:
                                              "${worker['FirstName']} ${worker['LastName']}",
                                          onTap: () {
                                            log("workers : $worker");
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ProfileDetails(
                                                        shiftData: worker,
                                                        isClient: false),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      );
    });
  }

  Widget MListTile(
      {required String title, String? description, required Function() onTap}) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! < 0) {
              onTap;
            }
          },
          onTap: onTap,
          child: Card(
            elevation: 0,
            color: colorScheme.secondaryContainer,
            child: ListTile(
              title: Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: colorScheme.primary)),
              subtitle: Text(description ?? ""),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          ),
        );
      },
    );
  }
}
