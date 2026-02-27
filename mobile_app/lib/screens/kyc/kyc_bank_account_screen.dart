import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class KYCBankAccountScreen extends StatelessWidget {
  const KYCBankAccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Accounts'),
        backgroundColor: AppTheme.kycColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'KYC Bank Account Screen\nComing Soon!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
