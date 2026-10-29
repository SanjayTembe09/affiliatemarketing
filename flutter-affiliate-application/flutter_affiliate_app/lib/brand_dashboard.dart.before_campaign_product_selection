import 'package:flutter/material.dart';
import 'api_service.dart';
import 'auth_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BrandDashboard extends StatefulWidget {
  const BrandDashboard({super.key});

  @override
  State<BrandDashboard> createState() => _BrandDashboardState();
}

class _BrandDashboardState extends State<BrandDashboard> {
  bool _isLoading = true;
  String? _errorMessage;

  // Selected Tab: 'direct' or 'marketplace'
  String _selectedTab = 'direct';

  // Master Lists
  List<dynamic> _allCampaigns = [];
  List<dynamic> _allCommissionLogs = [];
  List<dynamic> _allMarketplaceProducts = [];

  // Search filter for Marketplace products
  String _productSearchQuery = '';

  // Pagination State
  int _campaignPage = 1;
  final int _campaignLimit = 5;

  int _logPage = 1;
  final int _logLimit = 5;

  int _marketPage = 1;
  final int _marketLimit = 4;

  // Form Controllers for Campaign Creation
  final _campTitleController = TextEditingController();
  final _campDescController = TextEditingController();
  final _campUrlController = TextEditingController();
  final _campPayoutController = TextEditingController();
  final _campHashtagController = TextEditingController();
  String _selectedCategory = 'Tech'; // Default Category

  // Form Controllers for Marketplace Product Creation
  final _prodTitleController = TextEditingController();
  final _prodDescController = TextEditingController();
  final _prodUrlController = TextEditingController();
  final _prodImageController = TextEditingController();
  final _prodPriceController = TextEditingController();
  final _prodCommissionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBrandData();
    
    // Listen for changes in the campaign title to auto-calculate the payout
    _campTitleController.addListener(_autoCalculateCampaignPayout);
  }

  @override
  void dispose() {
    _campTitleController.dispose();
    _campDescController.dispose();
    _campUrlController.dispose();
    _campPayoutController.dispose();
    _campHashtagController.dispose();
    _prodTitleController.dispose();
    _prodDescController.dispose();
    _prodUrlController.dispose();
    _prodImageController.dispose();
    _prodPriceController.dispose();
    _prodCommissionController.dispose();
    super.dispose();
  }

  void _autoCalculateCampaignPayout() {
    final enteredTitle = _campTitleController.text.trim().toLowerCase();
    if (enteredTitle.isEmpty) return;

    // Search through loaded marketplace inventory for a matching product title
    final matchingProduct = _allMarketplaceProducts.firstWhere(
      (prod) => (prod['title'] ?? '').toString().toLowerCase() == enteredTitle,
      orElse: () => null,
    );

    if (matchingProduct != null) {
      final double price = double.tryParse(matchingProduct['price'].toString()) ?? 0.0;
      final double commission = double.tryParse(matchingProduct['commission_percentage'].toString()) ?? 10.0;
      
      // Formula: Payout = Retail Price * (Commission % / 100)
      final double calculatedPayout = price * (commission / 100);

      setState(() {
        _campPayoutController.text = calculatedPayout.toStringAsFixed(2);
        
        // Optionally auto-fill other fields if they are empty
        if (_campDescController.text.isEmpty) {
          _campDescController.text = matchingProduct['description'] ?? '';
        }
        if (_campUrlController.text.isEmpty) {
          _campUrlController.text = matchingProduct['product_url'] ?? '';
        }
      });
    }
  }

 Future<void> _fetchBrandData() async {
  if (!mounted) return;

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final results = await Future.wait([
      ApiService.getCampaigns(),
      ApiService.getCreatorProofLogs(),
      ApiService.getMarketplaceProducts(),
    ]);

    if (!mounted) return;

    setState(() {
      _allCampaigns = results[0];
      _allCommissionLogs = results[1];
      _allMarketplaceProducts = results[2];
      _isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _errorMessage =
          'Failed to load dashboard data. Please try again.';
    });

    debugPrint('Error fetching brand dashboard data: $e');
  }
}


  // Filtered Marketplace Products based on search query
  List<dynamic> get _filteredMarketplaceProducts {
    if (_productSearchQuery.isEmpty) {
      return _allMarketplaceProducts;
    }
    return _allMarketplaceProducts.where((prod) {
      final title = (prod['title'] ?? '').toString().toLowerCase();
      final desc = (prod['description'] ?? '').toString().toLowerCase();
      final query = _productSearchQuery.toLowerCase();
      return title.contains(query) || desc.contains(query);
    }).toList();
  }

  // Slicing for Pagination
  List<dynamic> get _paginatedCampaigns {
    final startIndex = (_campaignPage - 1) * _campaignLimit;
    if (startIndex >= _allCampaigns.length) return [];
    final endIndex = (startIndex + _campaignLimit < _allCampaigns.length) ? startIndex + _campaignLimit : _allCampaigns.length;
    return _allCampaigns.sublist(startIndex, endIndex);
  }

  List<dynamic> get _paginatedLogs {
    final startIndex = (_logPage - 1) * _logLimit;
    if (startIndex >= _allCommissionLogs.length) return [];
    final endIndex = (startIndex + _logLimit < _allCommissionLogs.length) ? startIndex + _logLimit : _allCommissionLogs.length;
    return _allCommissionLogs.sublist(startIndex, endIndex);
  }

  List<dynamic> get _paginatedMarketplace {
    final filtered = _filteredMarketplaceProducts;
    final startIndex = (_marketPage - 1) * _marketLimit;
    if (startIndex >= filtered.length) return [];
    final endIndex = (startIndex + _marketLimit < filtered.length) ? startIndex + _marketLimit : filtered.length;
    return filtered.sublist(startIndex, endIndex);
  }

  Future<void> _createCampaign() async {
    if (_campTitleController.text.isEmpty || _campPayoutController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Please fill out required campaign fields')),
      );
      return;
    }

    final result = await ApiService.postData('/api/campaigns/', {
      'title': _campTitleController.text.trim(),
      'description': _campDescController.text.trim(),
      'category': _selectedCategory,
      'product_url': _campUrlController.text.trim(),
      'required_hashtag': _campHashtagController.text.trim(),
      'payout_per_post': double.tryParse(_campPayoutController.text.trim()) ?? 0.0,
    });

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Campaign launched successfully!')),
      );
      _campTitleController.clear();
      _campDescController.clear();
      _campUrlController.clear();
      _campPayoutController.clear();
      _campHashtagController.clear();
      _fetchBrandData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${result['error']}')),
      );
    }
  }

  Future<void> _createProduct() async {
    if (_prodTitleController.text.isEmpty || _prodPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Please fill out required product fields')),
      );
      return;
    }

    final result = await ApiService.postData('/api/marketplace/', {
      'title': _prodTitleController.text.trim(),
      'description': _prodDescController.text.trim(),
      'product_url': _prodUrlController.text.trim(),
      'image_url': _prodImageController.text.trim().isEmpty ? null : _prodImageController.text.trim(),
      'price': double.tryParse(_prodPriceController.text.trim()) ?? 0.0,
      'commission_percentage': double.tryParse(_prodCommissionController.text.trim()) ?? 10.0,
    });

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Marketplace product added successfully!')),
      );
      _prodTitleController.clear();
      _prodDescController.clear();
      _prodUrlController.clear();
      _prodImageController.clear();
      _prodPriceController.clear();
      _prodCommissionController.clear();
      _fetchBrandData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${result['error']}')),
      );
    }
  }

  void _signout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCampaigns = _paginatedCampaigns;
    final currentLogs = _paginatedLogs;
    final currentMarketplace = _paginatedMarketplace;
    final filteredMarketplaceCount = _filteredMarketplaceProducts.length;

    // Filter campaigns for connected native blog networks matching exact category
    final travelCampaigns = _allCampaigns.where((c) => (c['category'] ?? '').toString().toLowerCase() == 'travel').toList();
    final beautyCampaigns = _allCampaigns.where((c) => (c['category'] ?? '').toString().toLowerCase() == 'beauty').toList();
    final techCampaigns = _allCampaigns.where((c) => (c['category'] ?? '').toString().toLowerCase() == 'tech').toList();

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
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '🔗 NanoConnect',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              'PREMIUM CORPORATE CONSOLE',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.lightBlue),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Brand Admin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                            const Text('ID: 3', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: _signout,
                              child: const Text('Sign Out', style: TextStyle(fontSize: 10, color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Brand Hub Pill Button matching visual layout
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.purpleAccent.withValues(alpha:0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('🏷️ ', style: TextStyle(fontSize: 14)),
                            Text('Brand Hub', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _isLoading ? null : _fetchBrandData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),

                    // Tab Switcher
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha:0.05)),
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
                                'Marketplace Products',
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
                    const SizedBox(height: 24),

                    if (_selectedTab == 'direct') ...[
                      // 1. CREATE NEW CAMPAIGN FORM
                      const Text('+ CREATE NEW CAMPAIGN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.lightBlue)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha:0.05)),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _campTitleController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Campaign Title',
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.black26,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _campDescController,
                              maxLines: 3,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Description...',
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.black26,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCategory,
                                  dropdownColor: const Color(0xFF0F172A),
                                  isExpanded: true,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  items: ['Tech', 'Travel', 'Beauty'].map((String category) {
                                    return DropdownMenuItem<String>(
                                      value: category,
                                      child: Text(category),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) setState(() => _selectedCategory = newValue);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _campUrlController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Product URL',
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.black26,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _campHashtagController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: '#hashtag',
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.black26,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _campPayoutController,
                              readOnly: true,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Payout (₹) - Auto calculated',
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.black26,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _createCampaign,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pinkAccent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('🚀 Launch Campaign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. ACTIVE CAMPAIGNS LIST WITH PAGINATION
                      const Text('📋 YOUR ACTIVE CAMPAIGNS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 12),
                      currentCampaigns.isEmpty
                          ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                "You haven't created any campaigns yet.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: currentCampaigns.length,
                              itemBuilder: (context, index) {
                                final camp = currentCampaigns[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withValues(alpha:0.05)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(camp['title'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                                      const SizedBox(height: 6),
                                      Text(camp['description'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      const Divider(color: Colors.white12, height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('₹${camp['payout_per_post'] ?? 0} per post', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                                          if (camp['required_hashtag'] != null && camp['required_hashtag'].toString().isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: Colors.purple.withValues(alpha:0.3), borderRadius: BorderRadius.circular(8)),
                                              child: Text(camp['required_hashtag'], style: const TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                      // Campaign Pagination Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _campaignPage > 1 ? () => setState(() => _campaignPage--) : null,
                            child: Text('PREV', style: TextStyle(color: _campaignPage > 1 ? Colors.lightBlue : Colors.grey)),
                          ),
                          Text('Page $_campaignPage of 3', style: const TextStyle(color: Colors.lightBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: (_campaignPage * _campaignLimit) < _allCampaigns.length ? () => setState(() => _campaignPage++) : null,
                            child: Text('NEXT', style: TextStyle(color: (_campaignPage * _campaignLimit) < _allCampaigns.length ? Colors.lightBlue : Colors.grey)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 3. CONNECTED NATIVE BLOG NETWORKS
                      const Text('💻 CONNECTED NATIVE BLOG NETWORKS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 12),
                      _buildBlogNetworkCard(context, 'Wander Trails', 'TRAVEL', travelCampaigns),
                      const SizedBox(height: 16),
                      _buildBlogNetworkCard(context, 'Glow Routine', 'BEAUTY', beautyCampaigns),
                      const SizedBox(height: 16),
                      _buildBlogNetworkCard(context, 'Tech Insider Daily', 'TECH', techCampaigns),
                      const SizedBox(height: 24),

                      // 4. APPROVED COMMISSION LOGS WITH PAGINATION
                      const Text('💰 APPROVED COMMISSION LOGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 12),
                      currentLogs.isEmpty
                          ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'No commission records available yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
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
                                    border: Border.all(color: Colors.white.withValues(alpha:0.05)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              log['title'] ?? log['entry_title'] ?? 'Commission Item',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text('MARKETPLACE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '₹${log['payout_amount'] ?? log['commission'] ?? 0.0}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                      // Commission Logs Pagination Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _logPage > 1 ? () => setState(() => _logPage--) : null,
                            child: Text('PREV', style: TextStyle(color: _logPage > 1 ? Colors.lightBlue : Colors.grey)),
                          ),
                          Text('Page $_logPage of 2', style: const TextStyle(color: Colors.lightBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: (_logPage * _logLimit) < _allCommissionLogs.length ? () => setState(() => _logPage++) : null,
                            child: Text('NEXT', style: TextStyle(color: (_logPage * _logLimit) < _allCommissionLogs.length ? Colors.lightBlue : Colors.grey)),
                          ),
                        ],
                      ),
                    ] else ...[
                      // MARKETPLACE PRODUCTS TAB

                      // 1. ADD PRODUCT FORM
                      const Text('+ ADD PRODUCT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.lightBlue)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha:0.05)),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _prodTitleController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Product Title',
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.black26,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _prodDescController,
                              maxLines: 3,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Product Description',
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.black26,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _prodUrlController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Product URL',
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.black26,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _prodImageController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Image URL',
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.black26,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _prodPriceController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: 'Retail Price (₹)',
                                      hintStyle: const TextStyle(color: Colors.grey),
                                      filled: true,
                                      fillColor: Colors.black26,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _prodCommissionController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: 'Commission (%)',
                                      hintStyle: const TextStyle(color: Colors.grey),
                                      filled: true,
                                      fillColor: Colors.black26,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _createProduct,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pinkAccent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('🛒 List Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. INVENTORY & SEARCH LIST WITH PAGINATION
                      const Text('🛒 YOUR INVENTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (val) {
                          setState(() {
                            _productSearchQuery = val;
                            _marketPage = 1; // Reset to page 1 on search change
                          });
                        },
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search listed products...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha:0.05))),
                        ),
                      ),
                      const SizedBox(height: 12),
                      currentMarketplace.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.inventory_2_outlined,
                                        size: 36,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _productSearchQuery.trim().isNotEmpty
                                            ? 'No products match your search.'
                                            : "You haven't listed any products yet.",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      if (_productSearchQuery.trim().isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _productSearchQuery = '';
                                              _marketPage = 1;
                                            });
                                          },
                                          child: const Text('Clear search'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              )
                              : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: currentMarketplace.length,
                              itemBuilder: (context, index) {
                                final prod = currentMarketplace[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withValues(alpha:0.05)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.white10,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Center(child: Text('🛍️', style: TextStyle(fontSize: 22))),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(prod['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                            const SizedBox(height: 4),
                                            Text(prod['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('₹${prod['price'] ?? 0.0}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                                Text('💰 ${prod['commission_percentage'] ?? 10.0}% Commission', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                                              ],
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _marketPage > 1 ? () => setState(() => _marketPage--) : null,
                            child: Text('Previous', style: TextStyle(color: _marketPage > 1 ? Colors.lightBlue : Colors.grey)),
                          ),
                          Text('Page $_marketPage of ${((filteredMarketplaceCount / _marketLimit).ceil() == 0 ? 1 : (filteredMarketplaceCount / _marketLimit).ceil())}', style: const TextStyle(color: Colors.lightBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: (_marketPage * _marketLimit) < filteredMarketplaceCount ? () => setState(() => _marketPage++) : null,
                            child: Text('Next', style: TextStyle(color: (_marketPage * _marketLimit) < filteredMarketplaceCount ? Colors.lightBlue : Colors.grey)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 3. CONNECTED NATIVE BLOG NETWORKS WITH CATEGORIES
                      const Text('💻 CONNECTED NATIVE BLOG NETWORKS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 12),
                      _buildBlogNetworkCard(context, 'Wander Trails', 'TRAVEL', travelCampaigns),
                      const SizedBox(height: 16),
                      _buildBlogNetworkCard(context, 'Glow Routine', 'BEAUTY', beautyCampaigns),
                      const SizedBox(height: 16),
                      _buildBlogNetworkCard(context, 'Tech Insider Daily', 'TECH', techCampaigns),
                      const SizedBox(height: 24),

                      // 4. APPROVED COMMISSION LOGS WITH PAGINATION
                      const Text('💰 APPROVED COMMISSION LOGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 12),
                      currentLogs.isEmpty
                          ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'No commission records available yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
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
                                    border: Border.all(color: Colors.white.withValues(alpha:0.05)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              log['title'] ?? log['entry_title'] ?? 'Commission Item',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text('MARKETPLACE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '₹${log['payout_amount'] ?? log['commission'] ?? 0.0}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                      // Commission Logs Pagination Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _logPage > 1 ? () => setState(() => _logPage--) : null,
                            child: Text('PREV', style: TextStyle(color: _logPage > 1 ? Colors.lightBlue : Colors.grey)),
                          ),
                          Text('Page $_logPage of 2', style: const TextStyle(color: Colors.lightBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: (_logPage * _logLimit) < _allCommissionLogs.length ? () => setState(() => _logPage++) : null,
                            child: Text('NEXT', style: TextStyle(color: (_logPage * _logLimit) < _allCommissionLogs.length ? Colors.lightBlue : Colors.grey)),
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

  Widget _buildBlogNetworkCard(BuildContext context, String networkName, String categoryLabel, List<dynamic> campaigns) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha:0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(networkName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha:0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(categoryLabel, style: const TextStyle(color: Colors.lightBlue, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final userString = prefs.getString('user');
              
              int currentUserId = 1;
              if (userString != null) {
                final userMap = jsonDecode(userString);
                currentUserId = userMap['id'] ?? 1;
              }

              final Uri url = Uri.parse('http://87.106.214.100:8080/api/blogs/${categoryLabel.toLowerCase()}?creator_id=$currentUserId');
              
              final bool launched = await launchUrl(
                url, 
                mode: LaunchMode.externalApplication,
              );
              
              if (!launched) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not launch partner blog URL')),
                );
              }
            },
            child: const Text('Launch Partner Website ↗', style: TextStyle(fontSize: 11, color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
          ),
          const Divider(color: Colors.white12, height: 20),
          const Text('ACTIVE INJECTED CAMPAIGNS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          campaigns.isEmpty
              ? const Text('No injected campaigns in this category', style: TextStyle(color: Colors.grey, fontSize: 11))
              : Column(
                  children: campaigns.map((camp) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Text('🎯 ', style: TextStyle(fontSize: 11)),
                          Expanded(
                            child: Text(
                              camp['title'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}