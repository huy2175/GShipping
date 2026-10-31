import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _authService = AuthService();

  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _errorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email này đã được đăng ký.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Hãy chọn mật khẩu mạnh hơn.';
      case 'operation-not-allowed':
        return 'Email/Password chưa được bật trong Firebase.';
      case 'network-request-failed':
        return 'Không có kết nối mạng. Hãy kiểm tra Internet.';
      case 'too-many-requests':
        return 'Bạn thử quá nhiều lần. Vui lòng thử lại sau.';
      default:
        return e.message ?? 'Đăng ký thất bại.';
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _authService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      // AuthGate tự cập nhật khi Firebase phát trạng thái đăng nhập.
      if (mounted) Navigator.of(context).pop();
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
      appBar: AppBar(
        title: const Text('Tạo tài khoản'),
        backgroundColor: const Color(0xFFF1F5F9),
        foregroundColor: const Color(0xFF1E3A8A),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              color: Colors.white,
              elevation: 2,
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
                        Icons.person_add_alt_1_rounded,
                        size: 54,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tham gia GShipping',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 28),
                      AuthTextField(
                        controller: _nameController,
                        label: 'Họ và tên',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập họ và tên.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
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
                        label: 'Mật khẩu (ít nhất 6 ký tự)',
                        icon: Icons.lock_outline,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Mật khẩu phải có ít nhất 6 ký tự.';
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _hidePassword = !_hidePassword;
                            });
                          },
                          child: Text(
                            _hidePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                          ),
                        ),
                      ),
                      AuthTextField(
                        controller: _confirmController,
                        label: 'Xác nhận mật khẩu',
                        icon: Icons.lock_reset_outlined,
                        obscureText: _hideConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _register(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng xác nhận mật khẩu.';
                          }
                          if (value != _passwordController.text) {
                            return 'Mật khẩu xác nhận không khớp.';
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _hideConfirmPassword = !_hideConfirmPassword;
                            });
                          },
                          child: Text(
                            _hideConfirmPassword
                                ? 'Hiện mật khẩu xác nhận'
                                : 'Ẩn mật khẩu xác nhận',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _loading ? null : _register,
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
                                  'TẠO TÀI KHOẢN',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Đã có tài khoản? Đăng nhập'),
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
