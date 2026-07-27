import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ProductScreen extends StatefulWidget {
  final String productId;

  const ProductScreen({super.key, required this.productId});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  Map<String, dynamic>? _productData;
  bool _isLoading = true;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/products/${widget.productId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _productData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _completePurchase() async {
    if (_productData == null) return;

    final token = await ApiService.getToken();
    final title = _productData!['title'];
    final orderTotal = double.tryParse(_productData!['retail_price'].toString()) ?? 0.0;

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/submissions/conversion'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'orderTotal': orderTotal,
        }),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _isSuccess = true;
          _statusMessage = '🎉 Purchase successful! Commission credited for: $title';
        });
      } else {
        setState(() {
          _isSuccess = false;
          _statusMessage = 'Error: ${result['message'] ?? 'Conversion failed'}';
        });
      }
    } catch (err) {
      setState(() {
        _isSuccess = false;
        _statusMessage = 'Error: Could not verify conversion.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _productData?['title'] ?? (_isLoading ? 'Loading Product...' : 'Product Not Found');
    final price = _productData?['retail_price'] ?? '0.00';

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🔒 SECURE E-COMMERCE CHECKOUT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.lightBlue),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹$price',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.lightBlue),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Simulate a real consumer checkout purchase sequence to trigger the tracking conversion loop.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading || _productData == null ? null : _completePurchase,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text('💳 Complete Purchase (Buy Now)', style: TextStyle(color: Colors.white)),
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _isSuccess ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}