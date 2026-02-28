import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class InsuranceClaimsScreen extends StatelessWidget {
  const InsuranceClaimsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance Claims'),
        backgroundColor: AppTheme.insuranceColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Insurance Claims Screen\nComing Soon!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
