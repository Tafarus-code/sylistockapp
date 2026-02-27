import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/status_card.dart';
import '../../widgets/common/progress_indicator.dart';
import '../../widgets/common/action_button.dart';
import 'kyc_upload_screen.dart';
import 'kyc_bank_account_screen.dart';
import 'kyc_compliance_screen.dart';

class KYCDashboardScreen extends StatefulWidget {
  const KYCDashboardScreen({Key? key}) : super(key: key);

  @override
  State<KYCDashboardScreen> createState() => _KYCDashboardScreenState();
}

class _KYCDashboardScreenState extends State<KYCDashboardScreen> {
  bool _isLoading = false;
  String _kycStatus = 'pending';
  int _overallScore = 0;
  List<Map<String, dynamic>> _requiredDocuments = [];
  List<Map<String, dynamic>> _bankAccounts = [];
  List<Map<String, dynamic>> _complianceChecks = [];

  @override
  void initState() {
    super.initState();
    _loadKYCStatus();
  }

  Future<void> _loadKYCStatus() async {
    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isLoading = false;
      _kycStatus = 'in_review';
      _overallScore = 75;
      _requiredDocuments = [
        {
          'type': 'national_id',
          'name': 'National ID Card',
          'status': 'verified',
          'uploaded': true,
          'icon': Icons.credit_card,
        },
        {
          'type': 'business_registration',
          'name': 'Business Registration',
          'status': 'pending',
          'uploaded': true,
          'icon': Icons.business,
        },
        {
          'type': 'tax_certificate',
          'name': 'Tax Certificate',
          'status': 'not_uploaded',
          'uploaded': false,
          'icon': Icons.receipt,
        },
      ];
      _bankAccounts = [
        {
          'bankName': 'Société Générale',
          'accountNumber': '****1234',
          'isPrimary': true,
          'isVerified': true,
          'icon': Icons.account_balance,
        },
        {
          'bankName': 'Ecobank',
          'accountNumber': '****5678',
          'isPrimary': false,
          'isVerified': false,
          'icon': Icons.account_balance_wallet,
        },
      ];
      _complianceChecks = [
        {
          'type': 'sanctions',
          'name': 'Sanctions Check',
          'status': 'passed',
          'riskScore': 15,
          'icon': Icons.gpp_good,
        },
        {
          'type': 'aml',
          'name': 'AML Check',
          'status': 'passed',
          'riskScore': 20,
          'icon': Icons.security,
        },
        {
          'type': 'fraud',
          'name': 'Fraud Detection',
          'status': 'flagged',
          'riskScore': 45,
          'icon': Icons.warning,
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadKYCStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildStatusCard(),
                    const SizedBox(height: 24),
                    _buildProgressSection(),
                    const SizedBox(height: 24),
                    _buildDocumentsSection(),
                    const SizedBox(height: 24),
                    _buildBankAccountsSection(),
                    const SizedBox(height: 24),
                    _buildComplianceSection(),
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
              Icons.verified_user,
              color: AppTheme.kycColor,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KYC Verification',
                    style: AppTheme.headline4,
                  ),
                  Text(
                    'Complete your verification to unlock banking features',
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

  Widget _buildStatusCard() {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (_kycStatus) {
      case 'approved':
        statusColor = AppTheme.successColor;
        statusText = 'Approved';
        statusIcon = Icons.verified;
        break;
      case 'rejected':
        statusColor = AppTheme.errorColor;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      case 'in_review':
        statusColor = AppTheme.warningColor;
        statusText = 'In Review';
        statusIcon = Icons.hourglass_empty;
        break;
      default:
        statusColor = AppTheme.primaryColor;
        statusText = 'Pending';
        statusIcon = Icons.pending;
    }
    
    return StatusCard(
      title: 'Verification Status',
      subtitle: 'Current status: $statusText',
      icon: statusIcon,
      color: statusColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Score',
                style: AppTheme.subtitle2,
              ),
              Text(
                '$_overallScore/100',
                style: AppTheme.headline6.copyWith(
                  color: _getScoreColor(_overallScore),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _overallScore / 100,
            backgroundColor: AppTheme.dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(_overallScore)),
          ),
          const SizedBox(height: 8),
          Text(
            _getScoreDescription(_overallScore),
            style: AppTheme.bodyText2.copyWith(
              color: AppTheme.onSurfaceColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Verification Progress',
                  style: AppTheme.headline6,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressStep('Basic Info', true, Icons.person),
            _buildProgressStep('Documents', false, Icons.description),
            _buildProgressStep('Bank Accounts', false, Icons.account_balance),
            _buildProgressStep('Compliance', false, Icons.security),
            _buildProgressStep('Final Review', false, Icons.gavel),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep(String title, bool completed, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: completed ? AppTheme.successColor : AppTheme.dividerColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              completed ? Icons.check : icon,
              color: completed ? AppTheme.onPrimaryColor : AppTheme.onSurfaceColor.withOpacity(0.6),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: AppTheme.bodyText1.copyWith(
              color: completed ? AppTheme.successColor : AppTheme.onSurfaceColor,
              fontWeight: completed ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
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
                      Icons.description,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Required Documents',
                      style: AppTheme.headline6,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _navigateToUploadScreen(),
                  child: const Text('Upload'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._requiredDocuments.map((doc) => _buildDocumentItem(doc)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(Map<String, dynamic> document) {
    Color statusColor;
    IconData statusIcon;
    
    switch (document['status']) {
      case 'verified':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.verified;
        break;
      case 'pending':
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.hourglass_empty;
        break;
      default:
        statusColor = AppTheme.dividerColor;
        statusIcon = Icons.upload_file;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            document['icon'],
            color: statusColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document['name'],
                  style: AppTheme.subtitle1,
                ),
                Text(
                  document['status'].toUpperCase(),
                  style: AppTheme.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            statusIcon,
            color: statusColor,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountsSection() {
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
                      Icons.account_balance,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Bank Accounts',
                      style: AppTheme.headline6,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _navigateToBankAccountScreen(),
                  child: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._bankAccounts.map((account) => _buildBankAccountItem(account)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBankAccountItem(Map<String, dynamic> account) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            account['icon'],
            color: account['isVerified'] ? AppTheme.successColor : AppTheme.dividerColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account['bankName'],
                  style: AppTheme.subtitle1,
                ),
                Text(
                  account['accountNumber'],
                  style: AppTheme.bodyText2.copyWith(
                    color: AppTheme.onSurfaceColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (account['isPrimary'])
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'PRIMARY',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.onPrimaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (account['isVerified'])
            Icon(
              Icons.verified,
              color: AppTheme.successColor,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildComplianceSection() {
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
                      Icons.security,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Compliance Checks',
                      style: AppTheme.headline6,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _navigateToComplianceScreen(),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._complianceChecks.map((check) => _buildComplianceItem(check)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceItem(Map<String, dynamic> check) {
    Color statusColor;
    
    switch (check['status']) {
      case 'passed':
        statusColor = AppTheme.successColor;
        break;
      case 'flagged':
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
            check['icon'],
            color: statusColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check['name'],
                  style: AppTheme.subtitle1,
                ),
                Text(
                  'Risk Score: ${check['riskScore']}',
                  style: AppTheme.bodyText2.copyWith(
                    color: AppTheme.onSurfaceColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              check['status'].toUpperCase(),
              style: AppTheme.caption.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_kycStatus == 'pending' || _kycStatus == 'rejected')
          ActionButton(
            text: 'Complete Verification',
            onPressed: _navigateToUploadScreen,
            icon: Icons.upload_file,
            color: AppTheme.primaryColor,
          ),
        if (_kycStatus == 'in_review')
          ActionButton(
            text: 'Check Status',
            onPressed: _loadKYCStatus,
            icon: Icons.refresh,
            color: AppTheme.primaryColor,
          ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => _navigateToComplianceScreen(),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.primaryColor),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.security, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'View Compliance Details',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _getScoreDescription(int score) {
    if (score >= 80) return 'Excellent - High chance of approval';
    if (score >= 60) return 'Good - Additional verification may be required';
    if (score >= 40) return 'Fair - Significant improvements needed';
    return 'Poor - Complete verification required';
  }

  void _navigateToUploadScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KYCUploadScreen()),
    );
  }

  void _navigateToBankAccountScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KYCBankAccountScreen()),
    );
  }

  void _navigateToComplianceScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KYCComplianceScreen()),
    );
  }
}
