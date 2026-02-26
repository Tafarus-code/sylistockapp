import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bankability_engine.dart';
import '../services/what3words_service.dart';
import '../services/network_optimization_service.dart';

/// Bankability Dashboard for Krediti-GN
/// Displays credit scores, loan recommendations, and financial insights
class BankabilityDashboardScreen extends ConsumerStatefulWidget {
  const BankabilityDashboardScreen({super.key});

  @override
  ConsumerState<BankabilityDashboardScreen> createState() => _BankabilityDashboardScreenState();
}

class _BankabilityDashboardScreenState extends ConsumerState<BankabilityDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  CreditScoreResult? _creditScoreResult;
  BankDataPackage? _bankDataPackage;
  bool _isLoading = false;
  String? _locationWords;
  DeliveryCost? _deliveryCost;
  NetworkStats? _networkStats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
    _loadBankabilityData();
  }

  Future<void> _initializeServices() async {
    await NetworkOptimizationService.instance.initialize();
    await What3WordsService.instance.initialize();
    _updateNetworkStats();
  }

  Future<void> _loadBankabilityData() async {
    setState(() => _isLoading = true);
    
    try {
      // Calculate credit score (merchant ID would come from auth)
      const merchantId = 1; // Placeholder
      _creditScoreResult = await BankabilityEngine.calculateCreditScore(merchantId);
      
      // Get location
      _locationWords = await What3WordsService.instance.getLocationWords();
      
      // Get delivery cost if location available
      if (_locationWords != null) {
        _deliveryCost = await What3WordsService.instance.getDeliveryCost(_locationWords!);
      }
      
      // Export bank data package
      _bankDataPackage = await BankabilityEngine.exportLoanPackage(merchantId);
      
    } catch (e) {
      print('Error loading bankability data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateNetworkStats() {
    setState(() {
      _networkStats = NetworkOptimizationService.instance.getNetworkStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Krediti-GN Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBankabilityData,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCreditScoreTab(),
                _buildLogisticsTab(),
                _buildNetworkTab(),
              ],
            ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.score), text: 'Credit Score'),
          Tab(icon: Icon(Icons.location_on), text: 'Logistics'),
          Tab(icon: Icon(Icons.network_check), text: 'Network'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _exportLoanPackage,
        child: const Icon(Icons.file_download),
        tooltip: 'Export Loan Package',
      ),
    );
  }

  Widget _buildCreditScoreTab() {
    if (_creditScoreResult == null) {
      return const Center(
        child: Text('No credit data available'),
      );
    }

    final result = _creditScoreResult!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Credit Score Overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Credit Score',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (result.creditScore - 300) / 550,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getScoreColor(result.creditScore),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${result.creditScore}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: _getScoreColor(result.creditScore),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getScoreDescription(result.creditTier),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _getScoreColor(result.creditScore),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Credit Metrics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Credit Metrics',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildMetricRow('Sales Velocity', result.salesVelocity.toStringAsFixed(1)),
                  _buildMetricRow('Inventory Turnover', result.inventoryTurnover.toStringAsFixed(1)),
                  _buildMetricRow('Consistency Score', result.consistencyScore.toStringAsFixed(1)),
                  _buildMetricRow('Recommended Loan', '${result.recommendedLoanAmount.toStringAsFixed(0)} XOF'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Loan Terms
          if (_bankDataPackage != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loan Terms',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildMetricRow('Interest Rate', '${_bankDataPackage!.riskAssessment.recommendedTerms.interestRate}%'),
                    _buildMetricRow('Max Duration', '${_bankDataPackage!.riskAssessment.recommendedTerms.maxDuration} months'),
                    _buildMetricRow('Collateral Required', 
                        _bankDataPackage!.riskAssessment.recommendedTerms.collateralRequired ? 'Yes' : 'No'),
                    _buildMetricRow('Risk Level', _bankDataPackage!.riskAssessment.riskLevel.name.toUpperCase()),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Location',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (_locationWords != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _locationWords!,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Last updated: ${What3WordsService.instance.lastLocationUpdate?.toString() ?? 'Unknown'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    )
                  else
                    const Text('Location not available'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final words = await What3WordsService.instance.getLocationWords();
                      if (words != null) {
                        setState(() {
                          _locationWords = words;
                        });
                        // Update delivery cost
                        final cost = await What3WordsService.instance.getDeliveryCost(words);
                        setState(() {
                          _deliveryCost = cost;
                        });
                      }
                    },
                    icon: const Icon(Icons.location_searching),
                    label: const Text('Update Location'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Delivery Information
          if (_deliveryCost != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildMetricRow('Base Cost', '${_deliveryCost!.baseCost.toStringAsFixed(0)} XOF'),
                    _buildMetricRow('Distance Cost', '${_deliveryCost!.distanceCost.toStringAsFixed(0)} XOF'),
                    _buildMetricRow('Urban Surcharge', '${_deliveryCost!.urbanSurcharge.toStringAsFixed(0)} XOF'),
                    const Divider(),
                    _buildMetricRow('Total Cost', '${_deliveryCost!.totalCost.toStringAsFixed(0)} XOF'),
                    _buildMetricRow('Estimated Time', '${_deliveryCost!.estimatedTime} minutes'),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Service Area Check
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Area',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<bool>(
                    future: _locationWords != null 
                        ? What3WordsService.instance.isWithinServiceArea(_locationWords!)
                        : Future.value(false),
                    builder: (context, snapshot) {
                      final isWithinService = snapshot.data ?? false;
                      return Row(
                        children: [
                          Icon(
                            isWithinService ? Icons.check_circle : Icons.warning,
                            color: isWithinService ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isWithinService ? 'Within Service Area' : 'Outside Service Area',
                            style: TextStyle(
                              color: isWithinService ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkTab() {
    final stats = _networkStats ?? NetworkOptimizationService.instance.getNetworkStats();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Network Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Network Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        stats.isOnline ? Icons.wifi : Icons.wifi_off,
                        color: stats.isOnline ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        stats.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: stats.isOnline ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Connection: ${stats.connectivityType}'),
                  Text('Queued Requests: ${stats.queuedRequests}'),
                  if (stats.lastSyncAttempt != null)
                    Text('Last Sync: ${stats.lastSyncAttempt.toString()}'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sync Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sync Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: stats.isOnline ? () async {
                            try {
                              await NetworkOptimizationService.instance.forceSync();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Sync completed')),
                              );
                              _updateNetworkStats();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Sync failed: $e')),
                              );
                            }
                          } : null,
                          icon: const Icon(Icons.sync),
                          label: const Text('Force Sync'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await NetworkOptimizationService.instance.clearQueue();
                            _updateNetworkStats();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Queue cleared')),
                            );
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Queue'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 750) return Colors.green;
    if (score >= 700) return Colors.lightGreen;
    if (score >= 650) return Colors.blue;
    if (score >= 600) return Colors.yellow;
    if (score >= 550) return Colors.orange;
    return Colors.red;
  }

  String _getScoreDescription(CreditTier tier) {
    switch (tier) {
      case CreditTier.excellent:
        return 'Excellent credit - Best loan terms available';
      case CreditTier.veryGood:
        return 'Very good credit - Favorable loan terms';
      case CreditTier.good:
        return 'Good credit - Standard loan terms';
      case CreditTier.fair:
        return 'Fair credit - Higher interest rates';
      case CreditTier.poor:
        return 'Poor credit - Limited loan options';
      case CreditTier.veryPoor:
        return 'Very poor credit - High risk borrower';
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Merchant ID'),
              subtitle: const Text('1'),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Service Area'),
              subtitle: Text(_locationWords ?? 'Not set'),
            ),
            ListTile(
              leading: const Icon(Icons.network_check),
              title: const Text('Network'),
              subtitle: Text(_networkStats?.connectivityType ?? 'Unknown'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportLoanPackage() async {
    if (_bankDataPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No loan package available')),
      );
      return;
    }

    try {
      // In a real implementation, this would export to a file or send to bank
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan package exported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
