import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class InsurancePremiumsScreen extends StatelessWidget {
  const InsurancePremiumsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Payments'),
        backgroundColor: AppTheme.insuranceColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Insurance Premiums Screen\nComing Soon!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
