import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:m_worker/utils/api.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:s3_storage/s3_storage.dart';

import '../../../utils/prefs.dart';

class IncidentFormScreen extends StatefulWidget {
  final String clientID;
  final String workerID;
  final Map prefilledInfo;
  const IncidentFormScreen(
      {super.key,
      required this.prefilledInfo,
      required this.clientID,
      required this.workerID});

  @override
  _IncidentFormScreenState createState() => _IncidentFormScreenState();
}

class _IncidentFormScreenState extends State<IncidentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {
    'FirstName': '',
    'LastName': '',
    'HazardAdditionalInfo': '',
    'Address': '',
    'Suburb': '',
    'State': '',
    'PostCode': '',
    'Phone': '',
    'AccidentType': '',
    'IncidentRelateTo': '',
    'IncidentDate': '',
    'IncidentTime': '',
    'IncidentLocation': '',
    'IncidentType': [], // Initialize as an empty list
    'IncidentDetail': '',
    'InjuryDetail': '',
    'IncidentCircumstance': '',
    'IncidentRestrictivePractice': [], // Initialize as an empty list
    'RestrictivePracticeUse': '',
    'SuggestionsToPreventReoccurrence': '',
    'ImmediateActionTaken': [], // Initialize as an empty list
    'IncidentOutcome': '',
    'HazardReportedBy': '',
    'MarkAsCompleted': false,
    'HazardRelateTo': '', // Add default value
    'HazardDate': '', // Add default value
    'HazardType': [], // Add default value
    'HazardDetail': '', // Add default value
    'Bucket': '',
    'Folder': '',
    'File': ''
  };

  @override
  initState() {
    super.initState();
    _formData['ClientID'] = widget.clientID;
    _formData['WorkerID'] = widget.workerID;
    _formData['IncidentID'] = DateTime.now().millisecondsSinceEpoch;
    _formData['AccidentType'] = 'Incident';
    _fetchClientData();
  }

  void _fetchClientData() async {
    final res =
        await Api.get('getClientDataForIncidentForm/${widget.clientID}');
    if (res['success']) {
      setState(() {
        _formData['FirstName'] = res['data'][0]['FirstName'].toString();
        _formData['LastName'] = res['data'][0]['LastName'].toString();
        _formData['Address'] = res['data'][0]['AddressLine1'].toString();
        _formData['Suburb'] = res['data'][0]['Suburb'].toString();
        _formData['PostCode'] = res['data'][0]['Postcode'].toString();
        _formData['Phone'] = res['data'][0]['Phone'].toString();
      });

      log('Form data: $_formData');
    }
  }

  bool get isIncident => _formData['AccidentType'] == 'Incident';
  bool get isHazard => _formData['AccidentType'] == 'Hazard/Risk';

  void _handleFormChange(String key, dynamic value) {
    setState(() {
      _formData[key] = value;
    });
  }

  String? _requiredFieldValidator(dynamic value) {
    try {
      if (value.toString().isEmpty) {
        return 'This field is required';
      }
    } catch (e) {
      return 'This field is required';
    }
    return null;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _generatePdf();
    }
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    final ByteData bytes = await rootBundle.load('assets/images/logo.png');
    final Uint8List byteList = bytes.buffer.asUint8List();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(pw.MemoryImage(byteList), width: 70),
              pw.SizedBox(height: 16),
              pw.Text('Incident Form', style: const pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 16),
              pw.Text('Incident ID: ${_formData['IncidentID']}'),
              pw.SizedBox(height: 5),
              pw.Text('Client ID: ${_formData['ClientID']}'),
              pw.SizedBox(height: 5),
              pw.Text('Worker ID: ${_formData['WorkerID']}'),
              pw.SizedBox(height: 5),
              pw.Text('First Name: ${_formData['FirstName']}'),
              pw.SizedBox(height: 5),
              pw.Text('Last Name: ${_formData['LastName']}'),
              pw.SizedBox(height: 5),
              pw.Text('Address: ${_formData['Address']}'),
              pw.SizedBox(height: 5),
              pw.Text('State: ${_formData['State']}'),
              pw.SizedBox(height: 5),
              pw.Text('PostCode: ${_formData['PostCode']}'),
              pw.SizedBox(height: 5),
              pw.Text('Phone: ${_formData['Phone']}'),
              pw.SizedBox(height: 5),
              pw.Text('Accident Type: ${_formData['AccidentType']}'),
              pw.SizedBox(height: 5),
              if (isIncident) ...[
                pw.Text('Incident Relate To: ${_formData['IncidentRelateTo']}'),
                pw.SizedBox(height: 5),
                pw.Text('Incident Date: ${_formData['IncidentDate']}'),
                pw.SizedBox(height: 5),
                pw.Text('Incident Time: ${_formData['IncidentTime']}'),
                pw.SizedBox(height: 5),
                pw.Text('Incident Location: ${_formData['IncidentLocation']}'),
                pw.SizedBox(height: 5),
                pw.Text('Type of Incident: ${_formData['IncidentType']}'),
                if ((_formData['IncidentType'] as List).contains('Other')) ...[
                  pw.SizedBox(height: 5),
                  pw.Text(
                      'Type of Incident Other: ${_formData['IncidentTypeOther']}'),
                ],
                pw.SizedBox(height: 5),
                pw.Text('Details of Incident: ${_formData['IncidentDetail']}'),
                pw.SizedBox(height: 5),
                pw.Text('Details of Injury: ${_formData['InjuryDetail']}'),
                pw.SizedBox(height: 5),
                pw.Text(
                    'Circumstances/Triggers: ${_formData['IncidentCircumstance']}'),
                pw.SizedBox(height: 5),
                pw.Text(
                    'Restrictive Practices Used: ${_formData['IncidentRestrictivePractice']}'),
                pw.SizedBox(height: 5),
                pw.Text(
                    'Incident Reported By: ${_formData['IncidentHazardReportedBy']}'),
                pw.SizedBox(height: 5),
              ],
              if (isHazard) ...[
                pw.Text('Hazard Relate To: ${_formData['HazardRelateTo']}'),
                pw.SizedBox(height: 5),
                pw.Text('Hazard Date: ${_formData['HazardDate']}'),
                pw.SizedBox(height: 5),
                pw.Text('Type of Hazard: ${_formData['HazardType']}'),
                pw.SizedBox(height: 5),
                pw.Text('Hazard Detail: ${_formData['HazardDetail']}'),
                pw.SizedBox(height: 5),
                pw.Text(
                    'Immediate Action Taken: ${_formData['ImmediateActionTaken']}'),
                pw.SizedBox(height: 5),
                pw.Text(
                    'Suggestions to Prevent Reoccurrence: ${_formData['SuggestionsToPreventReoccurrence']}'),
                pw.SizedBox(height: 5),
              ],
              pw.Text('Additional Info: ${_formData['HazardAdditionalInfo']}'),
              pw.SizedBox(height: 10),
              pw.Text(
                  'Client Involved: ${widget.prefilledInfo['ClientInvolved'] == true ? 'Yes' : 'No'}'),
              pw.SizedBox(height: 5),
              pw.Text(
                  'Worker Involved: ${widget.prefilledInfo['WorkerInvolved'] == true ? 'Yes' : 'No'}'),
              pw.SizedBox(height: 5),
              pw.Text(
                  'Property Damage: ${widget.prefilledInfo['PropertyDamage'] == true ? 'Yes' : 'No'}'),
              pw.SizedBox(height: 5),
              pw.Text('Level: ${widget.prefilledInfo['Level']}'),
              pw.SizedBox(height: 5),
              pw.Text('Date: ${widget.prefilledInfo['Date']}'),
              pw.SizedBox(height: 5),
              pw.Text('Time: ${widget.prefilledInfo['Time']}'),
              pw.SizedBox(height: 5),
              pw.Text('Summary: ${widget.prefilledInfo['Summary']}'),
              pw.SizedBox(height: 5),
            ],
          );
        },
      ),
    );

    final root = await getApplicationDocumentsDirectory();
    final file = File(
        '${root.path}/incident_form${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    try {
      final s3Storage = S3Storage(
        endPoint: 's3.ap-southeast-2.amazonaws.com',
        accessKey: dotenv.env['S3_ACCESS_KEY']!,
        secretKey: dotenv.env['S3_SECRET_KEY']!,
        region: 'ap-southeast-2',
      );

      final company = await Prefs.getCompanyName();

      await s3Storage.putObject(
        'moscaresolutions',
        '$company/client/${widget.clientID}/incidents/${file.path.split('/').last}',
        Stream<Uint8List>.value(Uint8List.fromList(file.readAsBytesSync())),
        onProgress: (progress) {
          log('Progress: $progress');
        },
      );

      setState(() {
        _formData['Bucket'] = 'moscaresolutions';
        _formData['Folder'] = '$company/client/${widget.clientID}/incidents/';
        _formData['File'] = file.path.split('/').last;
      });

      try {
        final data = {
          ..._formData,
          if (isIncident) ...{
            'IncidentSuggestion': _formData['SuggestionsToPreventReoccurrence'],
            'IncidentImmediateAction': _formData['ImmediateActionTaken']
          } else ...{
            'HazardSuggestion': _formData['SuggestionsToPreventReoccurrence'],
            'HazardAction': _formData['ImmediateActionTaken']
          }
        };

        final res = await Api.post('insertClientIncidentData', data);
        if (res.toString().isNotEmpty) {
          log('Incident form submitted successfully');
        } else {
          log('Error submitting form: ${res['message']}');
        }
      } catch (e) {
        log('Error submitting form: $e');
      }
    } catch (e) {
      log('Error uploading document: $e');
    } finally {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                'Incident Form'),
            content: const Text(
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                'Incident form has been submitted successfully'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text(
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                    'OK'),
              ),
            ],
          );
        },
      );
      file.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          'Incident Form',
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.black, size: 24),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Card(
                  color: Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            'Please Select'),
                        FormBuilderRadioGroup(
                          name: 'AccidentType',
                          validator: _requiredFieldValidator,
                          initialValue: 'Incident',
                          options: ['Incident', 'Hazard/Risk']
                              .map((option) =>
                                  FormBuilderFieldOption(value: option))
                              .toList(),
                          onChanged: (value) {
                            _handleFormChange('AccidentType', value.toString());
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  color: Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            'First Name'),
                        FormBuilderTextField(
                          validator: _requiredFieldValidator,
                          controller: TextEditingController(
                              text: _formData['FirstName']),
                          name: 'FirstName',
                          decoration: const InputDecoration(
                            hintText: 'Enter First Name',
                          ),
                          onChanged: (value) {
                            _handleFormChange('FirstName', value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  color: Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            'Last Name'),
                        FormBuilderTextField(
                          validator: _requiredFieldValidator,
                          name: 'LastName',
                          controller: TextEditingController(
                              text: _formData['LastName']),
                          decoration: const InputDecoration(
                            hintText: 'Enter Last Name',
                          ),
                          onChanged: (value) {
                            _handleFormChange('LastName', value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  color: Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            'Address'),
                        FormBuilderTextField(
                          validator: _requiredFieldValidator,
                          name: 'Address',
                          controller:
                              TextEditingController(text: _formData['Address']),
                          decoration: const InputDecoration(
                            hintText: 'Enter Address',
                          ),
                          onChanged: (value) {
                            _handleFormChange('Address', value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  color: Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            'Suburb'),
                        FormBuilderTextField(
                          validator: _requiredFieldValidator,
                          controller:
                              TextEditingController(text: _formData['Suburb']),
                          name: 'Suburb',
                          decoration: const InputDecoration(
                            hintText: 'Enter Suburb',
                          ),
                          onChanged: (value) {
                            _handleFormChange('Suburb', value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  color: Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            'State'),
                        FormBuilderTextField(
                          controller:
                              TextEditingController(text: _formData['State']),
                          name: 'State',
                          decoration: const InputDecoration(
                            hintText: 'Enter State',
                          ),
                          onChanged: (value) {
                            _handleFormChange('State', value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  color: Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            'Postcode'),
                        FormBuilderTextField(
                          name: 'PostCode',
                          controller: TextEditingController(
                              text: _formData['PostCode']),
                          decoration: const InputDecoration(
                            hintText: 'Enter PostCode',
                          ),
                          onChanged: (value) {
                            _handleFormChange('PostCode', value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  color: Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            'Phone'),
                        FormBuilderTextField(
                          validator: _requiredFieldValidator,
                          name: 'Phone',
                          controller:
                              TextEditingController(text: _formData['Phone']),
                          decoration: const InputDecoration(
                            hintText: 'Enter Phone',
                          ),
                          onChanged: (value) {
                            _handleFormChange('Phone', value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (isHazard) ...[
                  Card(
                    color: Colors.white,
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            'Details of the person Hazard / Risk relates to: ',
                          ),
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'Hazard Relate To'),
                          FormBuilderRadioGroup(
                            validator: _requiredFieldValidator,
                            name: 'HazardRelateTo',
                            options: [
                              'Client',
                              'Contractor',
                              'Employee',
                              'Visitor',
                              'Volunteer',
                              'Other'
                            ]
                                .map((option) =>
                                    FormBuilderFieldOption(value: option))
                                .toList(),
                            onChanged: (value) {
                              _handleFormChange(
                                  'HazardRelateTo', value.toString());
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'Hazard Date'),
                          FormBuilderDateTimePicker(
                            validator: _requiredFieldValidator,
                            name: 'HazardDate',
                            inputType: InputType.date,
                            format: DateFormat('dd/MM/yyyy'),
                            decoration: const InputDecoration(
                              hintText: 'Enter Hazard Date (dd/MM/yyyy)',
                            ),
                            onChanged: (value) {
                              _handleFormChange('HazardDate', value.toString());
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'Type of Hazard/Risk: '),
                          FormBuilderCheckboxGroup(
                              name: 'HazardType',
                              options: [
                                'Condition of Home (e.g. clutter, unsafe flooring)',
                                'COVID',
                                'Electrical Safety (e.g. frayed electrical cords, over-loaded power points, damaged electrical switched)',
                                'Equipment (e.g. broken walker, office chair)',
                                'Infection Risk (e.g. dog urinating inside)',
                                'Safety (e.g. snake, fire hazard, poor external lighting)',
                                'Slip / Trip / Fall (e.g. wet floor, uneven surface)',
                                'Other'
                              ]
                                  .map((option) =>
                                      FormBuilderFieldOption(value: option))
                                  .toList(),
                              onChanged: (value) {
                                _handleFormChange('HazardType', value);
                              }),
                          if ((_formData['HazardType'] as List)
                              .contains('Other')) ...[
                            const SizedBox(height: 16),
                            const Text(
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                                'Type of Hazard / Risk Other'),
                            FormBuilderTextField(
                              validator: _requiredFieldValidator,
                              name: 'HazardTypeOther',
                              decoration: const InputDecoration(
                                hintText: 'Enter Other',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  (_formData['HazardType'] as List).add(value!);
                                });
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'Hazard Detail'),
                          FormBuilderTextField(
                            validator: _requiredFieldValidator,
                            name: 'HazardDetail',
                            decoration: const InputDecoration(
                              hintText: 'Enter Hazard Detail',
                            ),
                            onChanged: (value) {
                              _handleFormChange('HazardDetail', value!);
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'Immediate Action Taken'),
                          FormBuilderCheckboxGroup(
                            validator: _requiredFieldValidator,
                            name: 'ImmediateActionTaken',
                            options: [
                              'Contacted Office',
                              'Contacted Next of Kin / Primary Contact',
                              'Hazard Removed',
                              'Other'
                            ]
                                .map((option) =>
                                    FormBuilderFieldOption(value: option))
                                .toList(),
                            onChanged: (value) {
                              _handleFormChange('ImmediateActionTaken', value);
                            },
                          ),
                          if ((_formData['ImmediateActionTaken'] as List)
                              .contains('Other')) ...[
                            const SizedBox(height: 16),
                            const Text(
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                                'Immediate Action Taken Other'),
                            FormBuilderTextField(
                              validator: _requiredFieldValidator,
                              name: 'ImmediateActionTakenOther',
                              decoration: const InputDecoration(
                                hintText: 'Enter Other',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  (_formData['ImmediateActionTaken'] as List)
                                      .add(value!);
                                });
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'Suggestions to prevent reoccurrence of hazard/risk'),
                          FormBuilderTextField(
                            validator: _requiredFieldValidator,
                            name: 'SuggestionsToPreventReoccurrence',
                            decoration: const InputDecoration(
                              hintText: 'Enter Details',
                            ),
                            onChanged: (value) {
                              _handleFormChange(
                                  'SuggestionsToPreventReoccurrence', value!);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (isIncident) ...[
                  Card(
                    color: Colors.white,
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            'Details of the person incident relates to: ',
                          ),
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'Incident Relates to: '),
                          FormBuilderRadioGroup(
                            validator: _requiredFieldValidator,
                            name: 'IncidentRelateTo',
                            options: [
                              'Client',
                              'Contractor',
                              'Employee',
                              'Visitor',
                              'Volunteer',
                              'Other'
                            ]
                                .map((option) =>
                                    FormBuilderFieldOption(value: option))
                                .toList(),
                            onChanged: (value) {
                              _handleFormChange(
                                  'IncidentRelateTo', value.toString());
                            },
                          ),
                          if (_formData['IncidentRelateTo'] == 'Other') ...[
                            const SizedBox(height: 16),
                            const Text(
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                                'Other'),
                            FormBuilderTextField(
                              validator: _requiredFieldValidator,
                              name: 'IncidentRelateToOther',
                              decoration: const InputDecoration(
                                hintText: 'Enter Other',
                              ),
                              onChanged: (value) {
                                _handleFormChange(
                                    'IncidentRelateTo', 'Other: $value');
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'Incident Date'),
                          FormBuilderDateTimePicker(
                            validator: _requiredFieldValidator,
                            name: 'IncidentDate',
                            inputType: InputType.date,
                            format: DateFormat('dd/MM/yyyy'),
                            decoration: const InputDecoration(
                              hintText: 'Enter Incident Date (dd/MM/yyyy)',
                            ),
                            onChanged: (value) {
                              _handleFormChange(
                                  'IncidentDate', value.toString());
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'Incident Time'),
                          FormBuilderDateTimePicker(
                            name: 'IncidentTime',
                            inputType: InputType.time,
                            format: DateFormat('h:mm a'),
                            decoration: const InputDecoration(
                              hintText: 'Enter Incident Time (HH:mm AA)',
                            ),
                            onChanged: (value) {
                              _handleFormChange(
                                  'IncidentTime', value.toString());
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'Incident Location'),
                          FormBuilderTextField(
                            validator: _requiredFieldValidator,
                            name: 'IncidentLocation',
                            decoration: const InputDecoration(
                              hintText: 'Enter Incident Location',
                            ),
                            onChanged: (value) {
                              _handleFormChange('IncidentLocation', value!);
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'Type of Incident: '),
                          FormBuilderCheckboxGroup(
                              name: 'IncidentType',
                              options: [
                                'Abuse (e.g. financial, physical, emotional, rights)',
                                'Behavioural (e.g. aggression, absconding, verbal abuse, sexual)',
                                'Fall',
                                'Medical Episode (e.g. seizure, choking, heart attack)',
                                'Missing Items / Theft',
                                'Near Miss (Client has left usual baseline behaviour)',
                                'Category 1 (Hospitalisation, death, major injury / property damage, police involved)',
                                'Category 2 (Hitting, Self-harm, property damage, requiring first aid)',
                                'Category 3 (Spitting, throwing, minor injury, no first aid required)',
                                'Infectious Material, body or hazardous substance exposure',
                                'Other'
                              ]
                                  .map((option) =>
                                      FormBuilderFieldOption(value: option))
                                  .toList(),
                              onChanged: (value) {
                                _handleFormChange('IncidentType', value);
                              }),
                          if ((_formData['IncidentType'] as List)
                              .contains('Other')) ...[
                            const SizedBox(height: 16),
                            const Text(
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                                'Type of Incident Other'),
                            FormBuilderTextField(
                              validator: _requiredFieldValidator,
                              name: 'IncidentTypeOther',
                              decoration: const InputDecoration(
                                hintText: 'Enter Other',
                              ),
                              onChanged: (value) {
                                _handleFormChange('IncidentType', [
                                  ..._formData['IncidentType'],
                                  'Other: $value'
                                ]);
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'Details of Incident'),
                          FormBuilderTextField(
                            validator: _requiredFieldValidator,
                            name: 'IncidentDetail',
                            decoration: const InputDecoration(
                              hintText: 'Details of Incident',
                            ),
                            onChanged: (value) {
                              _handleFormChange('IncidentDetail', value!);
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'Details of Injury (if applicable): Nature of injury (e.g. burn, sprain, cut, bruise, fracture, etc.) Location on body (e.g. head, arm, leg, back, etc.)'),
                          FormBuilderTextField(
                            validator: _requiredFieldValidator,
                            name: 'InjuryDetail',
                            decoration: const InputDecoration(
                              hintText: 'Details of Injury',
                            ),
                            onChanged: (value) {
                              _handleFormChange('InjuryDetail', value!);
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'Circumstances/Triggers Leading up to the Incident'),
                          FormBuilderTextField(
                            validator: _requiredFieldValidator,
                            name: 'IncidentCircumstance',
                            decoration: const InputDecoration(
                              hintText:
                                  'What were the circumstances/triggers/leading up to the incident',
                            ),
                            onChanged: (value) {
                              _handleFormChange('IncidentCircumstance', value!);
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'Were Restrictive Practices Used'),
                          FormBuilderCheckboxGroup(
                            name: 'IncidentRestrictivePractice',
                            options: [
                              'Chemical Restraint (e.g. medication)',
                              'Physical Restraint (e.g. MAPA/MAYBO)',
                              'Mechanical',
                              'Seclusion',
                              'Environmental',
                              'Other'
                            ]
                                .map((option) =>
                                    FormBuilderFieldOption(value: option))
                                .toList(),
                            onChanged: (value) {
                              _handleFormChange(
                                  'IncidentRestrictivePractice', value);
                            },
                          ),
                          if ((_formData['IncidentRestrictivePractice'] as List)
                              .contains('Other')) ...[
                            const SizedBox(height: 16),
                            const Text(
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                                'Other Restrictive Practices Used'),
                            FormBuilderTextField(
                              validator: _requiredFieldValidator,
                              name: 'IncidentRestrictivePracticeOther',
                              decoration: const InputDecoration(
                                hintText: 'Enter Other',
                              ),
                              onChanged: (value) {
                                _handleFormChange(
                                    'IncidentRestrictivePractice', [
                                  ..._formData['IncidentRestrictivePractice'],
                                  'Other: $value'
                                ]);
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'If used, please provide details of how the restrictive practices were used'),
                          FormBuilderTextField(
                            validator: _requiredFieldValidator,
                            name: 'RestrictivePracticeUse',
                            decoration: const InputDecoration(
                              hintText: 'Enter Details',
                            ),
                            onChanged: (value) {
                              _handleFormChange(
                                  'RestrictivePracticeUse', value!);
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'Suggestions to prevent reoccurrence of incident'),
                          FormBuilderTextField(
                            validator: _requiredFieldValidator,
                            name: 'SuggestionsToPreventReoccurrence',
                            decoration: const InputDecoration(
                              hintText: 'Enter Details',
                            ),
                            onChanged: (value) {
                              _handleFormChange(
                                  'SuggestionsToPreventReoccurrence', value!);
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'Immediate Action Taken'),
                          FormBuilderCheckboxGroup(
                            validator: _requiredFieldValidator,
                            name: 'ImmediateActionTaken',
                            options: [
                              'Contacted Office',
                              'Applied First Aid',
                              'Called Emergency Services (Police, Ambulance, Fire Brigade)',
                              'Contacted Next of Kin / Primary Contact',
                              'Person Requested No Action Be Taken',
                            ]
                                .map((option) =>
                                    FormBuilderFieldOption(value: option))
                                .toList(),
                            onChanged: (value) {
                              _handleFormChange('ImmediateActionTaken', value);
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'Outcome of Immediate Action Taken'),
                          FormBuilderRadioGroup(
                            validator: _requiredFieldValidator,
                            name: 'IncidentOutcome',
                            options: [
                              'Next of Kin / Primary Contact Contacted and Informed',
                              'Person Requested No Action Be Taken',
                              'Person Transported to Hospital',
                              'Other',
                            ]
                                .map((option) =>
                                    FormBuilderFieldOption(value: option))
                                .toList(),
                            onChanged: (value) {
                              _handleFormChange(
                                  'IncidentOutcome', value.toString());
                            },
                          ),
                          if (_formData['IncidentOutcome'] == 'Other') ...[
                            const SizedBox(height: 16),
                            const Text(
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                                'Outcome of Immediate Action Taken Other'),
                            FormBuilderTextField(
                              validator: _requiredFieldValidator,
                              name: 'IncidentOutcomeOther',
                              decoration: const InputDecoration(
                                hintText: 'Enter Other',
                              ),
                              onChanged: (value) {
                                _handleFormChange(
                                    'IncidentOutcome', 'Other: $value');
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Text(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              'Reported By'),
                          FormBuilderTextField(
                            validator: _requiredFieldValidator,
                            name: 'HazardReportedBy',
                            decoration: const InputDecoration(
                              hintText: 'Reported By',
                            ),
                            onChanged: (value) {
                              _handleFormChange('HazardReportedBy', value!);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                Card(
                  color: Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            'Additional Info (if any)'),
                        FormBuilderTextField(
                          validator: _requiredFieldValidator,
                          name: 'HazardAdditionalInfo',
                          decoration: const InputDecoration(
                            hintText: 'Enter Additional Info',
                          ),
                          onChanged: (value) {
                            _handleFormChange('HazardAdditionalInfo', value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  color: Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            'Mark as completed'),
                        FormBuilderCheckbox(
                          name: 'MarkAsCompleted',
                          onChanged: (value) {
                            _handleFormChange('MarkAsCompleted', value);
                          },
                          title: const Text(
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            'Completed',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
