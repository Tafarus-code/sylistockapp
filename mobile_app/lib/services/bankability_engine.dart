import '../models/inventory_item.dart';
import '../services/local_storage_service.dart';

/// Bankability Engine for Krediti-GN
/// Calculates real-time creditworthiness for informal merchants in Guinea
class BankabilityEngine {
  static const double _baseCreditScore = 300.0;
  static const double _maxCreditScore = 850.0;
  
  /// Calculate comprehensive credit score for a merchant
  static Future<CreditScoreResult> calculateCreditScore(int merchantId) async {
    try {
      final localStorage = LocalStorageService();
      final inventoryItems = localStorage.getInventoryItems();
      
      // Core metrics for credit scoring
      final salesVelocity = _calculateSalesVelocity(inventoryItems);
      final inventoryTurnover = _calculateInventoryTurnover(inventoryItems);
      final consistencyScore = _calculateConsistencyScore(inventoryItems);
      final diversityScore = _calculateDiversityScore(inventoryItems);
      final seasonalAdjustment = _calculateSeasonalAdjustment(inventoryItems);
      
      // Weighted credit score calculation
      final creditScore = _baseCreditScore +
          (salesVelocity * 0.35) +
          (inventoryTurnover * 0.25) +
          (consistencyScore * 0.20) +
          (diversityScore * 0.10) +
          (seasonalAdjustment * 0.10);
      
      // Cap at maximum score
      final finalScore = creditScore.clamp(_baseCreditScore, _maxCreditScore);
      
      // Determine credit tier
      final creditTier = _determineCreditTier(finalScore);
      
      // Calculate recommended loan amount (in XOF - West African CFA)
      final recommendedLoan = _calculateRecommendedLoan(finalScore, inventoryItems);
      
      return CreditScoreResult(
        creditScore: finalScore.round(),
        creditTier: creditTier,
        salesVelocity: salesVelocity,
        inventoryTurnover: inventoryTurnover,
        consistencyScore: consistencyScore,
        recommendedLoanAmount: recommendedLoan,
        lastUpdated: DateTime.now(),
        merchantId: merchantId,
      );
    } catch (e) {
      print('Error calculating credit score: $e');
      return CreditScoreResult.error(merchantId);
    }
  }
  
  /// Calculate sales velocity (items sold per day)
  static double _calculateSalesVelocity(List<InventoryItem> items) {
    if (items.isEmpty) return 0.0;
    
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    // Count items with recent activity (simulated sales)
    final recentItems = items.where((item) {
      return item.createdAt.isAfter(thirtyDaysAgo);
    }).length;
    
    // Base score: 0-200 points
    return (recentItems / 30.0 * 200).clamp(0.0, 200.0);
  }
  
  /// Calculate inventory turnover rate
  static double _calculateInventoryTurnover(List<InventoryItem> items) {
    if (items.isEmpty) return 0.0;
    
    // Simulate turnover based on item diversity and quantity
    final uniqueProducts = items.map((item) => item.barcode).toSet().length;
    final totalQuantity = items.fold<int>(0, (sum, item) => sum + item.quantity);
    
    // Base score: 0-150 points
    final turnoverScore = (uniqueProducts * 10 + (totalQuantity / 10)).clamp(0.0, 150.0);
    return turnoverScore;
  }
  
  /// Calculate consistency score (regular business activity)
  static double _calculateConsistencyScore(List<InventoryItem> items) {
    if (items.isEmpty) return 0.0;
    
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    // Check for daily activity patterns
    final recentItems = items.where((item) {
      return item.createdAt.isAfter(sevenDaysAgo);
    }).toList();
    
    // Group by day of week
    final Map<int, int> dailyActivity = {};
    for (final item in recentItems) {
      final dayOfWeek = item.createdAt.weekday;
      dailyActivity[dayOfWeek] = (dailyActivity[dayOfWeek] ?? 0) + 1;
    }
    
    // Consistency: more days with activity = higher score
    final activeDays = dailyActivity.length;
    
    // Base score: 0-100 points
    return (activeDays / 7.0 * 100).clamp(0.0, 100.0);
  }
  
  /// Calculate product diversity score
  static double _calculateDiversityScore(List<InventoryItem> items) {
    if (items.isEmpty) return 0.0;
    
    final uniqueCategories = items.map((item) => item.name.split(' ')[0]).toSet().length;
    
    // Base score: 0-50 points
    return (uniqueCategories * 5).clamp(0.0, 50.0).toDouble();
  }
  
  /// Calculate seasonal adjustment factors
  static double _calculateSeasonalAdjustment(List<InventoryItem> items) {
    if (items.isEmpty) return 0.0;
    
    final now = DateTime.now();
    final currentMonth = now.month;
    
    // Seasonal factors for Guinea (simplified)
    final seasonalFactors = {
      1: 1.1, // January (post-holiday)
      2: 0.9, // February
      3: 1.0, // March
      4: 1.2, // April (start of rainy season preparation)
      5: 1.1, // May
      6: 0.8, // June (rainy season)
      7: 0.7, // July (peak rainy)
      8: 0.8, // August
      9: 1.1, // September (harvest season)
      10: 1.3, // October (peak harvest)
      11: 1.2, // November
      12: 1.4, // December (holidays)
    };
    
    final factor = seasonalFactors[currentMonth] ?? 1.0;
    
    // Base score: 0-50 points
    return ((factor - 0.7) / 0.7 * 50).clamp(0.0, 50.0);
  }
  
  /// Determine credit tier based on score
  static CreditTier _determineCreditTier(double score) {
    if (score >= 750) return CreditTier.excellent;
    if (score >= 700) return CreditTier.veryGood;
    if (score >= 650) return CreditTier.good;
    if (score >= 600) return CreditTier.fair;
    if (score >= 550) return CreditTier.poor;
    return CreditTier.veryPoor;
  }
  
  /// Calculate recommended loan amount in XOF
  static double _calculateRecommendedLoan(double creditScore, List<InventoryItem> items) {
    if (items.isEmpty) return 0.0;
    
    // Base loan calculation
    final baseAmount = (creditScore - 300) * 1000; // XOF per point above base
    
    // Adjust for inventory value (simplified)
    final inventoryValue = items.length * 50000; // Estimated value per item
    
    // Final recommendation
    final recommendedAmount = (baseAmount + inventoryValue * 0.5).clamp(0.0, 5000000);
    
    return recommendedAmount.toDouble();
  }
  
  /// Export bank-ready data package
  static Future<BankDataPackage> exportLoanPackage(int merchantId) async {
    try {
      final creditResult = await calculateCreditScore(merchantId);
      final localStorage = LocalStorageService();
      final inventoryItems = localStorage.getInventoryItems();
      
      return BankDataPackage(
        merchantId: merchantId,
        creditScore: creditResult,
        inventoryData: inventoryItems,
        auditTrail: _generateAuditTrail(inventoryItems),
        riskAssessment: _generateRiskAssessment(creditResult),
        exportTimestamp: DateTime.now(),
      );
    } catch (e) {
      print('Error exporting loan package: $e');
      rethrow;
    }
  }
  
  /// Generate audit trail for bank compliance
  static List<AuditEntry> _generateAuditTrail(List<InventoryItem> items) {
    return items.map((item) => AuditEntry(
      timestamp: item.createdAt,
      action: 'SCAN',
      barcode: item.barcode,
      itemName: item.name,
      quantity: item.quantity,
      immutableHash: _generateHash(item),
    )).toList();
  }
  
  /// Generate risk assessment metrics
  static RiskAssessment _generateRiskAssessment(CreditScoreResult result) {
    return RiskAssessment(
      riskLevel: _calculateRiskLevel(result.creditScore),
      defaultProbability: _calculateDefaultProbability(result.creditScore),
      recommendedTerms: _getRecommendedTerms(result.creditTier),
      monitoringRequired: result.creditScore < 600,
    );
  }
  
  /// Calculate risk level
  static RiskLevel _calculateRiskLevel(int score) {
    if (score >= 750) return RiskLevel.low;
    if (score >= 650) return RiskLevel.medium;
    return RiskLevel.high;
  }
  
  /// Calculate default probability
  static double _calculateDefaultProbability(int score) {
    // Simplified probability calculation
    if (score >= 750) return 0.02; // 2%
    if (score >= 700) return 0.05; // 5%
    if (score >= 650) return 0.10; // 10%
    if (score >= 600) return 0.20; // 20%
    if (score >= 550) return 0.35; // 35%
    return 0.50; // 50%
  }
  
  /// Get recommended loan terms
  static LoanTerms _getRecommendedTerms(CreditTier tier) {
    switch (tier) {
      case CreditTier.excellent:
        return LoanTerms(interestRate: 8.0, maxDuration: 24, collateralRequired: false);
      case CreditTier.veryGood:
        return LoanTerms(interestRate: 10.0, maxDuration: 18, collateralRequired: false);
      case CreditTier.good:
        return LoanTerms(interestRate: 12.0, maxDuration: 12, collateralRequired: true);
      case CreditTier.fair:
        return LoanTerms(interestRate: 15.0, maxDuration: 9, collateralRequired: true);
      case CreditTier.poor:
        return LoanTerms(interestRate: 18.0, maxDuration: 6, collateralRequired: true);
      case CreditTier.veryPoor:
        return LoanTerms(interestRate: 22.0, maxDuration: 3, collateralRequired: true);
    }
  }
  
  /// Generate immutable hash for audit trail
  static String _generateHash(InventoryItem item) {
    // Simplified hash generation (in production, use proper cryptographic hash)
    final data = '${item.id}${item.barcode}${item.createdAt.millisecondsSinceEpoch}';
    return data.hashCode.toString();
  }
}

// Data models for Bankability Engine
class CreditScoreResult {
  final int creditScore;
  final CreditTier creditTier;
  final double salesVelocity;
  final double inventoryTurnover;
  final double consistencyScore;
  final double recommendedLoanAmount;
  final DateTime lastUpdated;
  final int merchantId;
  final bool hasError;
  
  CreditScoreResult({
    required this.creditScore,
    required this.creditTier,
    required this.salesVelocity,
    required this.inventoryTurnover,
    required this.consistencyScore,
    required this.recommendedLoanAmount,
    required this.lastUpdated,
    required this.merchantId,
  }) : hasError = false;
  
  CreditScoreResult.error(this.merchantId)
      : creditScore = 300,
        creditTier = CreditTier.veryPoor,
        salesVelocity = 0.0,
        inventoryTurnover = 0.0,
        consistencyScore = 0.0,
        recommendedLoanAmount = 0.0,
        lastUpdated = DateTime.now(),
        hasError = true;
}

enum CreditTier {
  excellent,
  veryGood,
  good,
  fair,
  poor,
  veryPoor,
}

class BankDataPackage {
  final int merchantId;
  final CreditScoreResult creditScore;
  final List<InventoryItem> inventoryData;
  final List<AuditEntry> auditTrail;
  final RiskAssessment riskAssessment;
  final DateTime exportTimestamp;
  
  BankDataPackage({
    required this.merchantId,
    required this.creditScore,
    required this.inventoryData,
    required this.auditTrail,
    required this.riskAssessment,
    required this.exportTimestamp,
  });
}

class AuditEntry {
  final DateTime timestamp;
  final String action;
  final String barcode;
  final String itemName;
  final int quantity;
  final String immutableHash;
  
  AuditEntry({
    required this.timestamp,
    required this.action,
    required this.barcode,
    required this.itemName,
    required this.quantity,
    required this.immutableHash,
  });
}

class RiskAssessment {
  final RiskLevel riskLevel;
  final double defaultProbability;
  final LoanTerms recommendedTerms;
  final bool monitoringRequired;
  
  RiskAssessment({
    required this.riskLevel,
    required this.defaultProbability,
    required this.recommendedTerms,
    required this.monitoringRequired,
  });
}

enum RiskLevel {
  low,
  medium,
  high,
}

class LoanTerms {
  final double interestRate; // Annual percentage rate
  final int maxDuration; // Months
  final bool collateralRequired;
  
  LoanTerms({
    required this.interestRate,
    required this.maxDuration,
    required this.collateralRequired,
  });
}
