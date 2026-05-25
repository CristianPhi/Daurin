import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'api_client.dart';
import 'HomePage.dart';
import 'RegisterPage.dart';
import 'pin_gate.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  late final Future<void> _googleSignInInit = _googleSignIn.initialize();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    unawaited(_googleSignInInit);
  }

  Future<void> _showStatusDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isSuccess
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                child: Icon(
                  isSuccess ? Icons.check : Icons.close,
                  color: isSuccess
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await postJsonWithFallback(
        path: '/auth/login',
        body: jsonEncode({
          'identifier': _identifierController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic>? data =
            jsonDecode(response.body) as Map<String, dynamic>?;
        final user = data?['user'];
        if (user is Map<String, dynamic>) {
          final email = user['email']?.toString() ?? '';
          final username = user['username']?.toString() ?? '';
          if (email.isNotEmpty) {
            await PinGate.setActiveAccountIdentifier(email);
          } else if (username.isNotEmpty) {
            await PinGate.setActiveAccountIdentifier(username);
          }
        }
        await _showStatusDialog(
          title: 'Login Berhasil',
          message: 'Selamat datang di Daurin.',
          isSuccess: true,
        );
        if (!mounted) {
          return;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        return;
      }

      final Map<String, dynamic>? data =
          jsonDecode(response.body) as Map<String, dynamic>?;
      final message = data?['message'];

      if (response.statusCode == 404) {
        await _showStatusDialog(
          title: 'Akun Tidak Ditemukan',
          message: 'Akun belum terdaftar. Silakan register dulu.',
          isSuccess: false,
        );
        if (!mounted) {
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RegisterPage(
              initialEmail: _identifierController.text.contains('@')
                  ? _identifierController.text
                  : '',
            ),
          ),
        );
        return;
      }

      await _showStatusDialog(
        title: 'Login Gagal',
        message: message is String
            ? message
            : 'Login gagal. Cek email/username dan password.',
        isSuccess: false,
      );
    } on TimeoutException {
      if (!mounted) {
        return;
      }
      await _showStatusDialog(
        title: 'Timeout',
        message:
            'Request timeout. ${apiConnectionHint()} Pastikan backend hidup di port 3000.',
        isSuccess: false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      await _showStatusDialog(
        title: 'Koneksi Gagal',
        message:
            'Tidak bisa terhubung ke server. ${error.toString()}. ${apiConnectionHint()}',
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      await _googleSignInInit;
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      if (!mounted) return;

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final response = await postJsonWithFallback(
        path: '/auth/google',
        body: jsonEncode({
          'idToken': googleAuth.idToken,
          'email': googleUser.email,
          'displayName': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
        }),
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await PinGate.setActiveAccountIdentifier(googleUser.email);
        await _showStatusDialog(
          title: 'Login Berhasil',
          message:
              'Selamat datang, ${googleUser.displayName ?? googleUser.email}!',
          isSuccess: true,
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        return;
      }

      final Map<String, dynamic>? data =
          jsonDecode(response.body) as Map<String, dynamic>?;
      await _showStatusDialog(
        title: 'Login Google Gagal',
        message: data?['message'] is String
            ? data!['message']
            : 'Gagal masuk dengan Google. Coba lagi.',
        isSuccess: false,
      );
    } catch (error) {
      if (!mounted) return;
      await _showStatusDialog(
        title: 'Koneksi Gagal',
        message: 'Tidak bisa login dengan Google: ${error.toString()}',
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login / Register Page'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email / Username:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _identifierController,
                decoration: InputDecoration(
                  hintText: 'Masukkan email / username kamu',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email atau username wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Password:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Masukkan password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login ke Daurin'),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegisterPage(
                        initialEmail: _identifierController.text.contains('@')
                            ? _identifierController.text
                            : '',
                      ),
                    ),
                  );
                },
                child: const Text('Do not have account? Register here'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

