import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:m_worker/utils/api.dart';
import 'package:s3_storage/s3_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IdCard extends StatefulWidget {
  const IdCard({super.key});

  @override
  State<IdCard> createState() => _IdCardState();
}

class _IdCardState extends State<IdCard> {
  late Map workerData = {};
  late String? _company = '';
  late String? _pfp = '';
  late Map<String, Color> _companyColors = {};

  @override
  void initState() {
    _fetchData();
    _getPfp();
    _fetchCompanyColors();
    super.initState();
  }

  void _fetchCompanyColors() async {
    try {
      final res = await Api.get('companyColors/');
      List colorsList = res;
      setState(() {
        _companyColors = {
          for (var color in colorsList)
            color['color_name']: _parseColor(color['color_value'])
        };
      });

      log(_companyColors.toString());
    } catch (e) {
      log('Error fetching company colors: $e');
    }
  }

  Color _parseColor(String colorValue) {
    if (colorValue.toLowerCase() == 'black') return Colors.black;
    if (colorValue.toLowerCase() == 'white') return Colors.white;
    if (colorValue.toLowerCase() == 'green') return Colors.green;
    if (colorValue.toLowerCase() == 'yellow') return Colors.yellow;
    if (colorValue.startsWith('#')) {
      return Color(int.parse(colorValue.substring(1), radix: 16) + 0xFF000000);
    }
    return Colors.grey; // Default color in case of unknown value
  }

  void _fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final workerID = prefs.getString('workerID');

    const storage = FlutterSecureStorage();
    final company = await storage.read(key: 'company');

    final res = await Api.get('getWorkerMasterData/$workerID');
    setState(() {
      workerData = res['data'][0];
      _company = company?.toUpperCase();
    });

    log(workerData.toString());
  }

  void _getPfp() async {
    try {
      final s3Storage = S3Storage(
        endPoint: 's3.ap-southeast-2.amazonaws.com',
        accessKey: dotenv.env['S3_ACCESS_KEY']!,
        secretKey: dotenv.env['S3_SECRET_KEY']!,
        region: 'ap-southeast-2',
      );

      const storage = FlutterSecureStorage();
      final company = await storage.read(key: 'company');
      final email = await storage.read(key: 'email');

      final url = await s3Storage.presignedGetObject(
        'moscaresolutions',
        '$company/worker/$email/profile_picture/pfp.jpg',
      );
      log('URL: $url');

      setState(() {
        _pfp = url;
      });
    } catch (e) {
      log('Error getting profile picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: _companyColors['light'] ?? Colors.black),
        title: Text('ID Card',
            style: TextStyle(color: _companyColors['light'] ?? Colors.black)),
        backgroundColor: _companyColors['primary'] ?? Colors.grey.shade200,
      ),
      backgroundColor: _companyColors['light'] ?? Colors.grey.shade200,
      body: workerData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        _company!,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _companyColors['primary'] ?? Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_pfp != null)
                        Image.network(
                          _pfp!,
                          width: 200,
                          height: 200,
                        ),
                      const SizedBox(height: 20),
                      Text(
                        workerData['FirstName'] + ' ' + workerData['LastName'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _companyColors['primary'] ?? Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        workerData['Email'],
                        style: TextStyle(
                          fontSize: 16,
                          color: _companyColors['info'] ?? Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        workerData['Phone'],
                        style: TextStyle(
                          fontSize: 16,
                          color: _companyColors['info'] ?? Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${workerData['WorkerType']}',
                        style: TextStyle(
                          fontSize: 24,
                          color: _companyColors['primary'] ?? Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Image.network(
                        'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${workerData['WorkerID']}&color=${_companyColors['primary'] != null ? _companyColors['primary']!.value.toRadixString(16).substring(2) : '000000'}&bgcolor=${_companyColors['light'] != null ? _companyColors['light']!.value.toRadixString(16).substring(2) : 'FFFFFF'}&qzone=1&margin=0&format=png',
                        width: 150,
                        height: 150,
                      ),

                      Text(
                        'ID: ${workerData['WorkerID']}',
                        style: TextStyle(
                          fontSize: 18,
                          color: _companyColors['secondary'] ?? Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
