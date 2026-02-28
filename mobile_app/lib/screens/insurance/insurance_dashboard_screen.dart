import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/status_card.dart';
import '../../widgets/common/progress_indicator.dart';
import '../../widgets/common/action_button.dart';
import 'insurance_policy_screen.dart';
import 'insurance_claims_screen.dart';
import 'insurance_premiums_screen.dart';

class InsuranceDashboardScreen extends StatefulWidget {
  const InsuranceDashboardScreen({Key? key}) : super(key: key);

  @override
  State<InsuranceDashboardScreen> createState() => _InsuranceDashboardScreenState();
}

class _InsuranceDashboardScreenState extends State<InsuranceDashboardScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _policies = [];
  List<Map<String, dynamic>> _claims = [];
  List<Map<String, dynamic>> _premiums = [];
  double _totalCoverage = 0;
  double _totalPremium = 0;
  int _activePolicies = 0;

  @override
  void initState() {
    super.initState();
    _loadInsuranceData();
  }

  Future<void> _loadInsuranceData() async {
    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isLoading = false;
      _policies = [
        {
          'id': '1',
          'policyNumber': 'POL-2024-001',
          'policyType': 'comprehensive',
          'status': 'active',
          'coverageAmount': 5000000.0,
          'premiumAmount': 175000.0,
          'startDate': '2024-01-01',
          'endDate': '2025-01-01',
          'daysUntilExpiry': 45,
          'icon': Icons.security,
        },
        {
          'id': '2',
          'policyNumber': 'POL-2024-002',
          'policyType': 'basic',
          'status': 'active',
          'coverageAmount': 2000000.0,
          'premiumAmount': 40000.0,
          'startDate': '2024-02-01',
          'endDate': '2025-02-01',
          'daysUntilExpiry': 75,
          'icon': Icons.shield,
        },
      ];
      _claims = [
        {
          'id': '1',
          'claimNumber': 'CLM-2024-001',
          'claimType': 'theft',
          'status': 'approved',
          'estimatedLoss': 500000.0,
          'approvedAmount': 450000.0,
          'submittedDate': '2024-01-15',
          'icon': Icons.warning,
        },
        {
          'id': '2',
          'claimNumber': 'CLM-2024-002',
          'claimType': 'damage',
          'status': 'under_review',
          'estimatedLoss': 200000.0,
          'approvedAmount': null,
          'submittedDate': '2024-02-10',
          'icon': Icons.build,
        },
      ];
      _premiums = [
        {
          'id': '1',
          'policyNumber': 'POL-2024-001',
          'premiumNumber': 'POL-2024-001-03',
          'amount': 14583.33,
          'dueDate': '2024-03-01',
          'status': 'paid',
          'paidDate': '2024-02-28',
        },
        {
          'id': '2',
          'policyNumber': 'POL-2024-001',
          'premiumNumber': 'POL-2024-001-04',
          'amount': 14583.33,
          'dueDate': '2024-04-01',
          'status': 'pending',
          'paidDate': null,
        },
      ];
      
      _totalCoverage = _policies.fold(0.0, (sum, policy) => sum + policy['coverageAmount']);
      _totalPremium = _policies.fold(0.0, (sum, policy) => sum + policy['premiumAmount']);
      _activePolicies = _policies.where((p) => p['status'] == 'active').length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInsuranceData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildOverviewCards(),
                    const SizedBox(height: 24),
                    _buildPoliciesSection(),
                    const SizedBox(height: 24),
                    _buildClaimsSection(),
                    const SizedBox(height: 24),
                    _buildPremiumsSection(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.security,
              color: AppTheme.insuranceColor,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insurance Protection',
                    style: AppTheme.headline4,
                  ),
                  Text(
                    'Manage your policies and claims',
                    style: AppTheme.bodyText2.copyWith(
                      color: AppTheme.onSurfaceColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Total Coverage',
                '₵${(_totalCoverage / 1000000).toStringAsFixed(1)}M',
                Icons.account_balance,
                AppTheme.insuranceColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                'Monthly Premium',
                '₵${(_totalPremium / 1000).toStringAsFixed(0)}K',
                Icons.payment,
                AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Active Policies',
                '$_activePolicies',
                Icons.policy,
                AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                'Pending Claims',
                '${_claims.where((c) => c['status'] == 'under_review').length}',
                Icons.pending,
                AppTheme.warningColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTheme.bodyText2.copyWith(
                color: AppTheme.onSurfaceColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTheme.headline6.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoliciesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.policy,
                      color: AppTheme.insuranceColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Active Policies',
                      style: AppTheme.headline6,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _navigateToPoliciesScreen(),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._policies.take(2).map((policy) => _buildPolicyItem(policy)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyItem(Map<String, dynamic> policy) {
    Color statusColor = policy['status'] == 'active' ? AppTheme.successColor : AppTheme.dividerColor;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            policy['icon'],
            color: statusColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  policy['policyNumber'],
                  style: AppTheme.subtitle1,
                ),
                Text(
                  '${policy['policyType'].toUpperCase()} • ₵${(policy['coverageAmount'] / 1000000).toStringAsFixed(1)}M',
                  style: AppTheme.bodyText2.copyWith(
                    color: AppTheme.onSurfaceColor.withOpacity(0.7),
                  ),
                ),
                if (policy['daysUntilExpiry'] <= 60)
                  Text(
                    'Expires in ${policy['daysUntilExpiry']} days',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₵${(policy['premiumAmount'] / 1000).toStringAsFixed(0)}K',
                style: AppTheme.subtitle2.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                policy['status'].toUpperCase(),
                style: AppTheme.caption.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClaimsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: AppTheme.warningColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Recent Claims',
                      style: AppTheme.headline6,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _navigateToClaimsScreen(),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._claims.take(2).map((claim) => _buildClaimItem(claim)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimItem(Map<String, dynamic> claim) {
    Color statusColor;
    
    switch (claim['status']) {
      case 'approved':
        statusColor = AppTheme.successColor;
        break;
      case 'rejected':
        statusColor = AppTheme.errorColor;
        break;
      case 'under_review':
        statusColor = AppTheme.warningColor;
        break;
      default:
        statusColor = AppTheme.dividerColor;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            claim['icon'],
            color: statusColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  claim['claimNumber'],
                  style: AppTheme.subtitle1,
                ),
                Text(
                  '${claim['claimType'].toUpperCase()} • ₵${(claim['estimatedLoss'] / 1000).toStringAsFixed(0)}K',
                  style: AppTheme.bodyText2.copyWith(
                    color: AppTheme.onSurfaceColor.withOpacity(0.7),
                  ),
                ),
                Text(
                  'Submitted: ${claim['submittedDate']}',
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.onSurfaceColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (claim['approvedAmount'] != null)
                Text(
                  '₵${(claim['approvedAmount']! / 1000).toStringAsFixed(0)}K',
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              Text(
                claim['status'].toUpperCase(),
                style: AppTheme.caption.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.payment,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Upcoming Premiums',
                      style: AppTheme.headline6,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _navigateToPremiumsScreen(),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._premiums.take(2).map((premium) => _buildPremiumItem(premium)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumItem(Map<String, dynamic> premium) {
    Color statusColor = premium['status'] == 'paid' ? AppTheme.successColor : AppTheme.warningColor;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.receipt,
            color: statusColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  premium['premiumNumber'],
                  style: AppTheme.subtitle1,
                ),
                Text(
                  'Due: ${premium['dueDate']}',
                  style: AppTheme.bodyText2.copyWith(
                    color: AppTheme.onSurfaceColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₵${premium['amount'].toStringAsFixed(0)}',
                style: AppTheme.subtitle2.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                premium['status'].toUpperCase(),
                style: AppTheme.caption.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ActionButton(
          text: 'Get New Policy',
          onPressed: _navigateToPoliciesScreen,
          icon: Icons.add,
          color: AppTheme.insuranceColor,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _navigateToClaimsScreen,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.warningColor),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning, color: AppTheme.warningColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'File a Claim',
                style: TextStyle(color: AppTheme.warningColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToPoliciesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InsurancePolicyScreen()),
    );
  }

  void _navigateToClaimsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InsuranceClaimsScreen()),
    );
  }

  void _navigateToPremiumsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InsurancePremiumsScreen()),
    );
  }
}
