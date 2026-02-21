// import 'package:flutter_datawedge/flutter_datawedge.dart';
// import 'package:dio/dio.dart';
//
// class ZebraScanService {
//   late FlutterDataWedge fdw;
//   final Dio _dio = Dio();
//   final String _backendUrl;
//
//   ZebraScanService({String backendUrl = 'http://localhost:8000/api/inventory/'})
//       : _backendUrl = backendUrl;
//
//   Future<void> init() async {
//     fdw = FlutterDataWedge();
//     await fdw.initialize();
//
//     // Create a profile on the TC26 automatically
//     await fdw.createDefaultProfile(profileName: "KreditiScanner");
//
//     // Listen for scans
//     fdw.onScanResult.listen((result) {
//       final data = result.data ?? '';
//       print("Scanned: $data");
//       _sendToBackend(data);
//     });
//   }
//
//   void _sendToBackend(String barcode) async {
//     try {
//       await _dio.post(_backendUrl, data: {"barcode": barcode});
//     } catch (e) {
//       print('Error sending barcode to backend: $e');
//     }
//   }
// }
//
