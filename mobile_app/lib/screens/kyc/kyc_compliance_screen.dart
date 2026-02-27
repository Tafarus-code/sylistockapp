import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class KYCComplianceScreen extends StatelessWidget {
  const KYCComplianceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compliance Checks'),
        backgroundColor: AppTheme.kycColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'KYC Compliance Screen\nComing Soon!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
