import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:m_worker/utils/api.dart';
import 'package:s3_storage/s3_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../bloc/theme_bloc.dart';

class ClientDocuments extends StatefulWidget {
  const ClientDocuments({super.key});

  @override
  State<ClientDocuments> createState() => _ClientDocumentsState();
}

class _ClientDocumentsState extends State<ClientDocuments> {
  final clientDocs = [];
  int clientId = 0;
  late List documentCategories = [];

  late double _uploadState = 0.0;
  late bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    // get the clientId from the named route
    final arg =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    log('args: $arg');
    setState(() {
      clientId = arg?['ClientID'] ?? 0;
    });
    _fetchData();
    super.didChangeDependencies();
  }

  void _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await Api.get('getClientDocumentData/$clientId');
      final Map<String, dynamic> res = response as Map<String, dynamic>;
      setState(() {
        clientDocs.clear();
        clientDocs.addAll(res['data']);
      });
      log('Client documents: $clientDocs');
    } catch (e) {
      log('Error fetching data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _downloadDoc(bucket, folder, file) async {
    try {
      final s3Storage = S3Storage(
        endPoint: 's3.ap-southeast-2.amazonaws.com',
        accessKey: dotenv.env['S3_ACCESS_KEY']!,
        secretKey: dotenv.env['S3_SECRET_KEY']!,
        region: 'ap-southeast-2',
      );

      final signedUrl =
          await s3Storage.presignedGetObject(bucket, '$folder/$file');
      log('Signed URL: $signedUrl');
      launch(signedUrl);
    } catch (e) {
      log('Error getting profile picture: $e');
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
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _fetchData();
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              _fetchData();
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _uploadState == 0.0
                      ? const SizedBox()
                      : LinearProgressIndicator(
                          value: _uploadState,
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                  const SizedBox(height: 10),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : clientDocs.isEmpty
                          ? const Center(
                              child: Text(
                                'No documents found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
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

  Widget _buildDocuments(ColorScheme colorScheme) {
    return Column(
      children: clientDocs.map((doc) {
        return Visibility(
          visible: doc['VisibilityWorker'] == 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    doc['Category'] ?? 'Uncategorized',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Card(
                  color: colorScheme.secondaryContainer,
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(
                      doc['DocName'],
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text(
                          doc['File'],
                          style: TextStyle(
                            color: colorScheme.primary.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          doc['Note'],
                          style: TextStyle(
                            color: colorScheme.secondary.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () {
                        log('${doc['Bucket']}, ${doc['Folder']}, ${doc['File']}');
                        _downloadDoc(doc['Bucket'], doc['Folder'], doc['File']);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
