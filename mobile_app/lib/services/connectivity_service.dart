import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  Stream<ConnectivityResult> get connectivityStream => _connectivity.onConnectivityChanged;
  
  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
  
  Future<ConnectivityResult> get connectivityResult async {
    return await _connectivity.checkConnectivity();
  }
  
  bool isOnline(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }
}
