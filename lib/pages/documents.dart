import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_worker/utils/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/theme_bloc.dart';

class Documents extends StatefulWidget {
  const Documents({super.key});

  @override
  State<Documents> createState() => _DocumentsState();
}

class _DocumentsState extends State<Documents> {
  final workerDocs = [];

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
      await Api.get('getWorkerDocumentData/$workerID');
      final Map<String, dynamic> res = response as Map<String, dynamic>;
      setState(() {
        workerDocs.clear();
        workerDocs.addAll(res['data']);
      });
    } catch (e) {
      log('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Documents'),
          ),
          body: SingleChildScrollView(
            child: RefreshIndicator(
              onRefresh: () async {
                _fetchData();
              },
              child: Column(
                children: [
                  workerDocs.isEmpty
                      ? const Center(
                    child: Text('No documents found', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  )
                      : _buildDocuments(colorScheme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocuments(colorScheme) {
    return Column(
      children: workerDocs.map((doc) {
        return ListTile(
          title: Text(doc['DocName']),
          trailing: IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              // download doc
            },
          ),
        );
      }).toList(),
    );
  }
}
