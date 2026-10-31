import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/auth_text_field.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _errorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Email hoặc mật khẩu không chính xác.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case 'too-many-requests':
        return 'Bạn thử quá nhiều lần. Vui lòng thử lại sau.';
      case 'network-request-failed':
        return 'Không có kết nối mạng. Hãy kiểm tra Internet.';
      case 'operation-not-allowed':
        return 'Email/Password chưa được bật trong Firebase.';
      default:
        return e.message ?? 'Đăng nhập thất bại.';
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Auth state listener trong app.dart sẽ tự chuyển màn hình.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_errorMessage(e))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xảy ra lỗi. Vui lòng thử lại.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.local_shipping_rounded,
                        size: 60,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'GShipping',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Đăng nhập để tiếp tục',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      AuthTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return 'Vui lòng nhập email.';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email)) {
                            return 'Email không đúng định dạng.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      AuthTextField(
                        controller: _passwordController,
                        label: 'Mật khẩu',
                        icon: Icons.lock_outline,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu.';
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() => _hidePassword = !_hidePassword);
                          },
                          child: Text(
                            _hidePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _loading ? null : _login,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'ĐĂNG NHẬP',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Flexible(child: Text('Chưa có tài khoản? ')),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text('Đăng ký ngay'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
