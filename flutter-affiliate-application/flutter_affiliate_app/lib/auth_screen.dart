import 'package:flutter/material.dart';
import 'api_service.dart';
import 'creator_dashboard.dart';
import 'brand_dashboard.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLoginMode = true;
  bool _isLoading = false; // Declared _isLoading here
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedRole = 'creator';
  String? _message;
  bool _isError = false;

  void _handleSubmit() async {
    setState(() {
      _message = null;
      _isLoading = true;
    });

    try {
      final result = await ApiService.authenticate(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: _selectedRole,
        isLogin: isLoginMode,
      );

      if (!mounted) return;

      if (result['success']) {
        if (isLoginMode) {
          final responseData = result['data'];
          final userRole = responseData['user']?['role'] ?? responseData['role'] ?? _selectedRole;

          if (userRole == 'brand') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BrandDashboard()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CreatorDashboard()),
            );
          }
        } else {
          setState(() {
            _isError = false;
            _message = '✅ Registration successful! Please sign in.';
            isLoginMode = true;
          });
        }
      } else {
        setState(() {
          _isError = true;
          _message = '❌ Error: ${result['error']}';
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _message = '❌ Connection failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.lightBlue, Colors.indigo]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text('🔗', style: TextStyle(fontSize: 24))),
                ),
                const SizedBox(height: 16),
                const Text('NanoConnect', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('SECURE PLATFORM ACCESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.lightBlue)),
                const SizedBox(height: 24),
                
                // Toggle Tabs
                Container(
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => isLoginMode = true),
                          style: TextButton.styleFrom(backgroundColor: isLoginMode ? const Color(0xFF0F172A) : Colors.transparent),
                          child: Text('Sign In', style: TextStyle(color: isLoginMode ? Colors.lightBlue : Colors.grey)),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => isLoginMode = false),
                          style: TextButton.styleFrom(backgroundColor: !isLoginMode ? const Color(0xFF0F172A) : Colors.transparent),
                          child: Text('Register', style: TextStyle(color: !isLoginMode ? Colors.lightBlue : Colors.grey)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_message != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: _isError ? Colors.red.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_message!, style: TextStyle(color: _isError ? Colors.redAccent : Colors.greenAccent)),
                        ),
                      if (!isLoginMode) ...[
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Full Name', labelStyle: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Email Address', labelStyle: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: Colors.grey)),
                      ),
                      if (!isLoginMode) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          dropdownColor: const Color(0xFF0F172A),
                          items: const [
                            DropdownMenuItem(value: 'creator', child: Text('Creator', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'brand', child: Text('Brand / Advertiser', style: TextStyle(color: Colors.white))),
                          ],
                          onChanged: (val) => setState(() => _selectedRole = val!),
                          decoration: const InputDecoration(labelText: 'Account Role', labelStyle: TextStyle(color: Colors.grey)),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: Colors.blue,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(isLoginMode ? 'Sign In' : 'Create Account'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}