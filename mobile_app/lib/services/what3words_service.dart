import 'package:flutter/services.dart';

/// what3words Logistics Integration for Krediti-GN
/// Provides 3m accuracy delivery in unaddressed markets of Guinea
class What3WordsService {
  static const MethodChannel _channel = MethodChannel('com.kreditign.what3words');
  static What3WordsService? _instance;
  static What3WordsService get instance => _instance ??= What3WordsService._();
  
  What3WordsService._();
  
  bool _isInitialized = false;
  String? _lastKnownLocation;
  DateTime? _lastLocationUpdate;
  
  /// Initialize what3words service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize what3words API
      await _channel.invokeMethod('initialize');
      _isInitialized = true;
      print('what3words service initialized');
    } catch (e) {
      print('what3words initialization failed: $e');
    }
  }
  
  /// Convert GPS coordinates to what3words address
  Future<String?> getLocationWords() async {
    await initialize();
    
    try {
      final result = await _channel.invokeMethod('getCurrentLocation');
      
      if (result != null) {
        final locationData = Map<String, dynamic>.from(result);
        final words = locationData['words'] as String?;
        final coordinates = locationData['coordinates'] as Map<String, double>?;
        
        if (words != null && coordinates != null) {
          _lastKnownLocation = words;
          _lastLocationUpdate = DateTime.now();
          
          print('Location: $words (${coordinates['latitude']}, ${coordinates['longitude']})');
          return words;
        }
      }
    } catch (e) {
      print('Error getting location words: $e');
    }
    
    return null;
  }
  
  /// Convert what3words address to GPS coordinates
  Future<Map<String, double>?> getCoordinates(String threeWordAddress) async {
    await initialize();
    
    try {
      final result = await _channel.invokeMethod('convertToCoordinates', {
        'words': threeWordAddress,
      });
      
      if (result != null) {
        final coordinates = Map<String, double>.from(result);
        return {
          'latitude': coordinates['latitude'] ?? 0.0,
          'longitude': coordinates['longitude'] ?? 0.0,
        };
      }
    } catch (e) {
      print('Error converting to coordinates: $e');
    }
    
    return null;
  }
  
  /// Get nearby what3words addresses for delivery optimization
  Future<List<NearbyLocation>> getNearbyLocations({
    String? centerWords,
    double radiusKm = 1.0,
    int limit = 10,
  }) async {
    await initialize();
    
    try {
      final result = await _channel.invokeMethod('getNearbyLocations', {
        'centerWords': centerWords ?? _lastKnownLocation,
        'radiusKm': radiusKm,
        'limit': limit,
      });
      
      if (result != null && result is List) {
        final locations = <NearbyLocation>[];
        
        for (final item in result) {
          final locationData = Map<String, dynamic>.from(item);
          locations.add(NearbyLocation(
            words: locationData['words'] as String,
            coordinates: {
              'latitude': locationData['latitude'] as double,
              'longitude': locationData['longitude'] as double,
            },
            distance: locationData['distance'] as double,
            relevance: locationData['relevance'] as double,
          ));
        }
        
        return locations;
      }
    } catch (e) {
      print('Error getting nearby locations: $e');
    }
    
    return [];
  }
  
  /// Optimize delivery route based on what3words locations
  Future<DeliveryRoute> optimizeDeliveryRoute(List<String> deliveryAddresses) async {
    await initialize();
    
    try {
      final result = await _channel.invokeMethod('optimizeRoute', {
        'addresses': deliveryAddresses,
      });
      
      if (result != null) {
        final routeData = Map<String, dynamic>.from(result);
        
        final waypoints = <RouteWaypoint>[];
        if (routeData['waypoints'] is List) {
          for (final waypoint in routeData['waypoints']) {
            final wpData = Map<String, dynamic>.from(waypoint);
            waypoints.add(RouteWaypoint(
              words: wpData['words'] as String,
              coordinates: {
                'latitude': wpData['latitude'] as double,
                'longitude': wpData['longitude'] as double,
              },
              estimatedTime: wpData['estimatedTime'] as int,
              distance: wpData['distance'] as double,
            ));
          }
        }
        
        return DeliveryRoute(
          totalDistance: routeData['totalDistance'] as double,
          totalTime: routeData['totalTime'] as int,
          waypoints: waypoints,
          optimized: routeData['optimized'] as bool,
        );
      }
    } catch (e) {
      print('Error optimizing delivery route: $e');
    }
    
    return DeliveryRoute.empty();
  }
  
  /// Validate what3words address format
  static bool isValidThreeWordAddress(String address) {
    if (address.isEmpty) return false;
    
    final parts = address.split('.');
    if (parts.length != 3) return false;
    
    // Check if each part contains only letters and numbers
    for (final part in parts) {
      if (part.isEmpty || part.length > 15) return false;
      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(part)) return false;
    }
    
    return true;
  }
  
  /// Get location metadata for Guinea regions
  Future<LocationMetadata?> getLocationMetadata(String threeWordAddress) async {
    await initialize();
    
    try {
      final result = await _channel.invokeMethod('getLocationMetadata', {
        'words': threeWordAddress,
      });
      
      if (result != null) {
        final metadata = Map<String, dynamic>.from(result);
        return LocationMetadata(
          country: metadata['country'] as String? ?? 'Guinea',
          region: metadata['region'] as String? ?? 'Unknown',
          city: metadata['city'] as String? ?? 'Unknown',
          district: metadata['district'] as String? ?? 'Unknown',
          postalCode: metadata['postalCode'] as String?,
          isUrban: metadata['isUrban'] as bool? ?? false,
          populationDensity: metadata['populationDensity'] as double? ?? 0.0,
        );
      }
    } catch (e) {
      print('Error getting location metadata: $e');
    }
    
    return null;
  }
  
  /// Check if location is within service area
  Future<bool> isWithinServiceArea(String threeWordAddress) async {
    final metadata = await getLocationMetadata(threeWordAddress);
    if (metadata == null) return false;
    
    // Check if location is in Guinea and within service regions
    if (metadata.country != 'Guinea') return false;
    
    // Major service areas in Guinea
    final serviceRegions = {
      'Conakry', 'Kindia', 'Boké', 'Fria', 'Mamou',
      'Labé', 'Kankan', 'Siguiri', 'Kouroussa', 'Dabola',
      'Macenta', 'Nzérékoré', 'Beyla', 'Lola', 'Yomou', 'Pita', 'Dalaba'
    };
    
    return serviceRegions.contains(metadata.region) || 
           serviceRegions.contains(metadata.city);
  }
  
  /// Get delivery cost estimate based on location
  Future<DeliveryCost> getDeliveryCost(String threeWordAddress) async {
    await initialize();
    
    try {
      final result = await _channel.invokeMethod('getDeliveryCost', {
        'words': threeWordAddress,
      });
      
      if (result != null) {
        final costData = Map<String, dynamic>.from(result);
        return DeliveryCost(
          baseCost: costData['baseCost'] as double,
          distanceCost: costData['distanceCost'] as double,
          urbanSurcharge: costData['urbanSurcharge'] as double,
          totalCost: costData['totalCost'] as double,
          currency: costData['currency'] as String? ?? 'XOF',
          estimatedTime: costData['estimatedTime'] as int,
        );
      }
    } catch (e) {
      print('Error getting delivery cost: $e');
    }
    
    // Fallback cost calculation
    return DeliveryCost.fallback();
  }
  
  /// Get last known location
  String? get lastKnownLocation => _lastKnownLocation;
  
  /// Get last location update time
  DateTime? get lastLocationUpdate => _lastLocationUpdate;
  
  /// Check if service is ready
  bool get isReady => _isInitialized;
  
  /// Cleanup resources
  void dispose() {
    _isInitialized = false;
    _lastKnownLocation = null;
    _lastLocationUpdate = null;
  }
}

// Data models for what3words integration
class NearbyLocation {
  final String words;
  final Map<String, double> coordinates;
  final double distance; // in meters
  final double relevance; // 0.0 to 1.0
  
  NearbyLocation({
    required this.words,
    required this.coordinates,
    required this.distance,
    required this.relevance,
  });
}

class DeliveryRoute {
  final double totalDistance; // in kilometers
  final int totalTime; // in minutes
  final List<RouteWaypoint> waypoints;
  final bool optimized;
  
  DeliveryRoute({
    required this.totalDistance,
    required this.totalTime,
    required this.waypoints,
    required this.optimized,
  });
  
  DeliveryRoute.empty()
      : totalDistance = 0.0,
        totalTime = 0,
        waypoints = [],
        optimized = false;
}

class RouteWaypoint {
  final String words;
  final Map<String, double> coordinates;
  final int estimatedTime; // in minutes from previous waypoint
  final double distance; // in kilometers from previous waypoint
  
  RouteWaypoint({
    required this.words,
    required this.coordinates,
    required this.estimatedTime,
    required this.distance,
  });
}

class LocationMetadata {
  final String country;
  final String region;
  final String city;
  final String district;
  final String? postalCode;
  final bool isUrban;
  final double populationDensity;
  
  LocationMetadata({
    required this.country,
    required this.region,
    required this.city,
    required this.district,
    this.postalCode,
    required this.isUrban,
    required this.populationDensity,
  });
}

class DeliveryCost {
  final double baseCost;
  final double distanceCost;
  final double urbanSurcharge;
  final double totalCost;
  final String currency;
  final int estimatedTime; // in minutes
  
  DeliveryCost({
    required this.baseCost,
    required this.distanceCost,
    required this.urbanSurcharge,
    required this.totalCost,
    required this.currency,
    required this.estimatedTime,
  });
  
  DeliveryCost.fallback()
      : baseCost = 500.0, // 500 XOF base
        distanceCost = 100.0, // 100 XOF per km
        urbanSurcharge = 200.0, // 200 XOF urban surcharge
        totalCost = 800.0,
        currency = 'XOF',
        estimatedTime = 30;
}
