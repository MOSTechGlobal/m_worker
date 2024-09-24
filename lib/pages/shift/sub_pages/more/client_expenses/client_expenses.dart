import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_worker/utils/api.dart';

import '../../../../../bloc/theme_bloc.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  int clientId = 0;
  int shiftId = 0;
  bool _isLoading = false;
  final clientExpenses = [];

  @override
  void didChangeDependencies() {
    final arg =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    log('args: $arg');
    setState(() {
      clientId = arg?['ClientID'] ?? 0;
      shiftId = arg?['ShiftID'] ?? 0;
    });
    _fetchExpensesOfShift();
    super.didChangeDependencies();
  }

  Future<void> _fetchExpensesOfShift() async {
    try {
      final response = await Api.get('getClientExpensesDataByShiftId/$shiftId');
      final Map<String, dynamic> res = response as Map<String, dynamic>;
      setState(() {
        clientExpenses.clear();
        clientExpenses.addAll(res['data']);
      });
      log('Expenses of shift: $res');
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
            actions: [
              IconButton(
                onPressed: () {
                  _fetchExpensesOfShift();
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
            title: Text(
              'Shift Expenses',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            backgroundColor: colorScheme.surface,
          ),
          backgroundColor: colorScheme.surface,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).pushNamed(
                '/shift_more_client_expenses/add',
                arguments: {
                  'ClientID': clientId,
                  'ShiftID': shiftId,
                },
              );
            },
            child: const Icon(Icons.add),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              _fetchExpensesOfShift();
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : clientExpenses.isEmpty
                          ? const Center(
                              child: Text(
                                'No documents found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : _buildExpenses(colorScheme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpenses(ColorScheme colorScheme) {
    return Column(
      children: clientExpenses.map((expense) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(
                '/shift_more_client_expenses/add',
                arguments: {
                  'ClientID': clientId,
                  'ShiftID': shiftId,
                  'ExpenseID': expense['ID'], // Pass ExpenseID
                },
              );
            },
            child: Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      expense['Description'],
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$ ${expense['TotalAmount']}',
                      style:
                          TextStyle(color: colorScheme.onSurface, fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
