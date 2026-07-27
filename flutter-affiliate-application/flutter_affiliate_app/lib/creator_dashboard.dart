import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'auth_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class CreatorDashboard extends StatefulWidget {
  const CreatorDashboard({super.key});

  @override
  State<CreatorDashboard> createState() => _CreatorDashboardState();
}

class _CreatorDashboardState extends State<CreatorDashboard> {
  bool _isLoading = true;
  String? _errorMessage;

  // Selected Tab: 'direct' or 'marketplace'
  String _selectedTab = 'direct';

  // Logged-in Creator ID
  int _currentCreatorId = 1; // Default fallback

  // Dynamic Dashboard Stats
  double _totalEarned = 0.0;
  int _totalClicks = 0;
  double _conversionRate = 0.0;

  // Raw Masters for Client-Side Pagination & Slicing
  List<dynamic> _allCampaigns = [];
  List<dynamic> _allProofLogs = [];
  List<dynamic> _allMarketplaceProducts = [];

  // Pagination Configuration & State
  int _campaignPage = 1;
  final int _campaignLimit = 5;

  int _logPage = 1;
  final int _logLimit = 5;

  int _marketPage = 1;
  final int _marketLimit = 4;

  // Controllers for X Post URL inputs
  final Map<int, TextEditingController> _urlControllers = {};

  @override
  void initState() {
    super.initState();
    _loadCreatorProfileAndData();
  }

  Future<void> _loadCreatorProfileAndData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Retrieve the logged-in creator ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = jsonDecode(userString);
        if (userData != null && userData['id'] != null) {
          _currentCreatorId = userData['id'] is int 
              ? userData['id'] 
              : int.tryParse(userData['id'].toString()) ?? 1;
        }
      }
    } catch (e) {
      debugPrint('Error loading creator profile info: $e');
    }

    await _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<dynamic> campaignsList = [];
      List<dynamic> logsList = [];
      List<dynamic> marketList = [];
      Map<String, dynamic> statsData = {};

      try {
        campaignsList = await ApiService.getCampaigns();
      } catch (e) {
        debugPrint('Error fetching campaigns: $e');
      }

      try {
        logsList = await ApiService.getCreatorProofLogs();
      } catch (e) {
        debugPrint('Error fetching proof-logs: $e');
      }

      try {
        marketList = await ApiService.getMarketplaceProducts();
      } catch (e) {
        debugPrint('Error fetching marketplace products: $e');
      }

      // Fetch live backend overview stats (total_earned, total_clicks, conversion_rate)
      try {
        statsData = await ApiService.getStatsOverview(_currentCreatorId);
      } catch (e) {
        debugPrint('Error fetching stats overview: $e');
      }

      if (!mounted) return;

      setState(() {
        _allCampaigns = campaignsList;
        _allProofLogs = logsList;
        _allMarketplaceProducts = marketList;

        // Assign backend calculated stats directly
        _totalEarned = (statsData['total_earned'] is num) 
            ? statsData['total_earned'].toDouble() 
            : (double.tryParse(statsData['total_earned']?.toString() ?? '0') ?? 0.0);
            
        _totalClicks = (statsData['total_clicks'] is num) 
            ? statsData['total_clicks'].toInt() 
            : (int.tryParse(statsData['total_clicks']?.toString() ?? '0') ?? 0);
            
        _conversionRate = (statsData['conversion_rate'] is num) 
            ? statsData['conversion_rate'].toDouble() 
            : (double.tryParse(statsData['conversion_rate']?.toString() ?? '0') ?? 0.0);

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dashboard data: $e';
      });
    }
  }

  // Get current chunk of campaigns for active page (5 items at a time)
  List<dynamic> get _paginatedCampaigns {
    final startIndex = (_campaignPage - 1) * _campaignLimit;
    if (startIndex >= _allCampaigns.length) return [];
    final endIndex = (startIndex + _campaignLimit < _allCampaigns.length) ? startIndex + _campaignLimit : _allCampaigns.length;
    return _allCampaigns.sublist(startIndex, endIndex);
  }

  // Get current chunk of proof logs for active page (5 items at a time)
  List<dynamic> get _paginatedProofLogs {
    final startIndex = (_logPage - 1) * _logLimit;
    if (startIndex >= _allProofLogs.length) return [];
    final endIndex = (startIndex + _logLimit < _allProofLogs.length) ? startIndex + _logLimit : _allProofLogs.length;
    return _allProofLogs.sublist(startIndex, endIndex);
  }

  // Get current chunk of marketplace products for active page (4 items at a time)
  List<dynamic> get _paginatedMarketplaceProducts {
    final startIndex = (_marketPage - 1) * _marketLimit;
    if (startIndex >= _allMarketplaceProducts.length) return [];
    final endIndex = (startIndex + _marketLimit < _allMarketplaceProducts.length) ? startIndex + _marketLimit : _allMarketplaceProducts.length;
    return _allMarketplaceProducts.sublist(startIndex, endIndex);
  }

  void _calculateDynamicStats() {
    double earnedSum = 0.0;
    int clicksSum = 0;
    int conversionsSum = 0;

    for (var log in _allProofLogs) {
      final rawAmount = log['payout_amount'] ?? log['commission'] ?? log['amount'] ?? log['earnings'] ?? 0;
      earnedSum += (rawAmount is num) ? rawAmount.toDouble() : (double.tryParse(rawAmount.toString()) ?? 0.0);
    }

    for (var camp in _allCampaigns) {
      final clicks = camp['clicks'] ?? camp['total_clicks'] ?? 0;
      clicksSum += (clicks is num) ? clicks.toInt() : (int.tryParse(clicks.toString()) ?? 0);

      final conversions = camp['conversions'] ?? camp['successful_conversions'] ?? 0;
      conversionsSum += (conversions is num) ? conversions.toInt() : (int.tryParse(conversions.toString()) ?? 0);
    }

    for (var prod in _allMarketplaceProducts) {
      final clicks = prod['clicks'] ?? prod['total_clicks'] ?? 0;
      clicksSum += (clicks is num) ? clicks.toInt() : (int.tryParse(clicks.toString()) ?? 0);

      final conversions = prod['conversions'] ?? prod['successful_conversions'] ?? 0;
      conversionsSum += (conversions is num) ? conversions.toInt() : (int.tryParse(conversions.toString()) ?? 0);
    }

    double conversionPct = 0.0;
    if (clicksSum > 0) {
      conversionPct = (conversionsSum / clicksSum) * 100.0;
    }

    _totalEarned = earnedSum; 
    _totalClicks = clicksSum;
    _conversionRate = conversionPct;
  }

  Future<void> _submitVerification(int campaignId, String postUrl) async {
    if (postUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Please enter a valid X post URL')),
      );
      return;
    }

    final result = await ApiService.postData('/api/submissions', {
      'campaign_id': campaignId,
      'post_url': postUrl,
      'creator_id': _currentCreatorId,
    });

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Verification proof submitted successfully!')),
      );
      _fetchDashboardData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${result['error']}')),
      );
    }
  }

  void _copyAffiliateLink(dynamic prodId) async {
    // Construct tracking route URL containing the actual logged-in user/creator ID
    final trackingUrl = 'http://87.106.214.100:8080/ref/$_currentCreatorId/$prodId';
    
    Clipboard.setData(ClipboardData(text: trackingUrl));

    // Automatically open in browser
  final uri = Uri.parse(trackingUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📋 Affiliate tracking link copied: $trackingUrl')),
    );
  }

  void _signout() async {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCampaigns = _paginatedCampaigns;
    final currentLogs = _paginatedProofLogs;
    final currentMarketplace = _paginatedMarketplaceProducts;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.lightBlue))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top App Bar / Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '🔗 NanoConnect',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              'PREMIUM CREATOR SUITE',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.lightBlue),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: _signout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            side: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                      ),

                    // Portal Navigation Pill
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '👤 Creator Portal (ID: $_currentCreatorId)',
                          style: const TextStyle(color: Colors.lightBlue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tab Switcher (Direct Campaigns vs Affiliate Marketplace)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () => setState(() => _selectedTab = 'direct'),
                              style: TextButton.styleFrom(
                                backgroundColor: _selectedTab == 'direct' ? const Color(0xFF1E293B) : Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Text('🎯', style: TextStyle(fontSize: 14)),
                              label: Text(
                                'Direct Campaigns',
                                style: TextStyle(
                                  color: _selectedTab == 'direct' ? Colors.lightBlue : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () => setState(() => _selectedTab = 'marketplace'),
                              style: TextButton.styleFrom(
                                backgroundColor: _selectedTab == 'marketplace' ? const Color(0xFF1E293B) : Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Text('🛒', style: TextStyle(fontSize: 14)),
                              label: Text(
                                'Affiliate Marketplace',
                                style: TextStyle(
                                  color: _selectedTab == 'marketplace' ? Colors.lightBlue : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Metrics Cards Grid
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TOTAL EARNED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 6),
                                Text(
                                  '₹${_totalEarned.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.lightBlue),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TOTAL CLICKS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 6),
                                Text(
                                  '$_totalClicks',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('CONVERSION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 6),
                                Text(
                                  '${_conversionRate.toStringAsFixed(1)}%',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // CONDITIONAL TAB VIEWS
                    if (_selectedTab == 'direct') ...[
                      const Text(
                        '🎯 ACTIVE CAMPAIGNS (5 per page)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),

                      currentCampaigns.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Center(child: Text('No active campaigns found', style: TextStyle(color: Colors.grey))),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: currentCampaigns.length,
                              itemBuilder: (context, index) {
                                final camp = currentCampaigns[index];
                                final campId = camp['id'] ?? index;
                                _urlControllers.putIfAbsent(campId, () => TextEditingController());

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        camp['title'] ?? 'Campaign Title',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        camp['description'] ?? 'Promote product to your followers!',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _urlControllers[campId],
                                              style: const TextStyle(color: Colors.white, fontSize: 13),
                                              decoration: InputDecoration(
                                                hintText: 'Enter X post URL',
                                                hintStyle: const TextStyle(color: Colors.grey),
                                                filled: true,
                                                fillColor: Colors.black26,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: BorderSide.none,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () => _submitVerification(campId, _urlControllers[campId]!.text.trim()),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.lightBlue,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            ),
                                            child: const Text('Verify', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                      // Campaign Pagination Controls
                      if (_allCampaigns.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _campaignPage > 1
                                  ? () => setState(() => _campaignPage--)
                                  : null,
                              child: Text('PREV', style: TextStyle(color: _campaignPage > 1 ? Colors.lightBlue : Colors.grey)),
                            ),
                            Text('Page $_campaignPage', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            TextButton(
                              onPressed: (_campaignPage * _campaignLimit) < _allCampaigns.length
                                  ? () => setState(() => _campaignPage++)
                                  : null,
                              child: Text('NEXT', style: TextStyle(color: (_campaignPage * _campaignLimit) < _allCampaigns.length ? Colors.lightBlue : Colors.grey)),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),

                      const Text(
                        '📋 VERIFICATION PROOF LOGS (5 per page)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),

                      currentLogs.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Center(child: Text('No verification proof logs available', style: TextStyle(color: Colors.grey))),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: currentLogs.length,
                              itemBuilder: (context, index) {
                                final log = currentLogs[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              log['entry_title'] ?? log['title'] ?? log['campaign_title'] ?? log['post_url'] ?? 'Verified Proof Log',
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              log['status'] ?? log['type'] ?? 'APPROVED',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.lightBlue),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₹${log['payout_amount'] ?? log['commission'] ?? log['amount'] ?? log['reward'] ?? '0.00'}',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                      // Proof Logs Pagination Controls
                      if (_allProofLogs.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _logPage > 1
                                  ? () => setState(() => _logPage--)
                                  : null,
                              child: Text('PREV', style: TextStyle(color: _logPage > 1 ? Colors.lightBlue : Colors.grey)),
                            ),
                            Text('Page $_logPage', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            TextButton(
                              onPressed: (_logPage * _logLimit) < _allProofLogs.length
                                  ? () => setState(() => _logPage++)
                                  : null,
                              child: Text('NEXT', style: TextStyle(color: (_logPage * _logLimit) < _allProofLogs.length ? Colors.lightBlue : Colors.grey)),
                            ),
                          ],
                        ),
                    ] else ...[
                      const Text(
                        '🛍️ AFFILIATE MARKETPLACE PRODUCTS (4 per page)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),

                      currentMarketplace.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Center(child: Text('No marketplace products found', style: TextStyle(color: Colors.grey))),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: currentMarketplace.length,
                              itemBuilder: (context, index) {
                                final prod = currentMarketplace[index];
                                final prodId = prod['id'] ?? prod['campaign_id'] ?? index;
                                final imageUrl = prod['image_url'] ?? prod['image'] ?? 'https://via.placeholder.com/150';
                                final title = prod['title'] ?? prod['name'] ?? 'Product Title';
                                final description = prod['description'] ?? 'Explore this amazing product for your audience!';
                                final price = prod['price'] ?? prod['amount'] ?? 1999.00;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Product Thumbnail Image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          imageUrl,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 70,
                                            height: 70,
                                            color: Colors.black26,
                                            child: const Icon(Icons.image, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Product Details & Copy Link Button
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              description,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '₹$price',
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.lightBlue),
                                            ),
                                            const SizedBox(height: 10),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: ElevatedButton.icon(
                                                onPressed: () => _copyAffiliateLink(prodId),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF1E293B),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                                                ),
                                                icon: const Text('📋', style: TextStyle(fontSize: 12)),
                                                label: const Text('Copy Link', style: TextStyle(color: Colors.white, fontSize: 12)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                      // Marketplace Pagination Controls
                      if (_allMarketplaceProducts.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _marketPage > 1
                                  ? () => setState(() => _marketPage--)
                                  : null,
                              child: Text('PREV', style: TextStyle(color: _marketPage > 1 ? Colors.lightBlue : Colors.grey)),
                            ),
                            Text('Page $_marketPage', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            TextButton(
                              onPressed: (_marketPage * _marketLimit) < _allMarketplaceProducts.length
                                  ? () => setState(() => _marketPage++)
                                  : null,
                              child: Text('NEXT', style: TextStyle(color: (_marketPage * _marketLimit) < _allMarketplaceProducts.length ? Colors.lightBlue : Colors.grey)),
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}