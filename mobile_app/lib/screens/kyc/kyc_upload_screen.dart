import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class KYCUploadScreen extends StatelessWidget {
  const KYCUploadScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Documents'),
        backgroundColor: AppTheme.kycColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'KYC Upload Screen\nComing Soon!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
