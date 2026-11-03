import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/remote/firebase_bootstrap.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _passwordVisible = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    if (!FirebaseBootstrap.initialized) {
      final reason = FirebaseBootstrap.initializationError;
      setState(() {
        _error = reason == null
            ? 'Firebase غير مهيأ. راجع إعداد Android في README.md.'
            : 'فشل تشغيل Firebase: $reason\nأعد إعداد Android بالأمر الموضح في README.md.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!AppConstants.isAdminEmail(credential.user?.email)) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          setState(() => _error = 'هذا الحساب لا يملك صلاحية الأدمن.');
        }
        return;
      }
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (exception) {
      setState(() => _error = _authMessage(exception.code));
    } catch (_) {
      setState(() => _error = 'تعذر تسجيل الدخول. تحقق من الاتصال والإعدادات.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _authMessage(String code) => switch (code) {
    'invalid-email' => 'صيغة البريد الإلكتروني غير صحيحة.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
    'too-many-requests' => 'محاولات كثيرة. انتظر قليلًا ثم أعد المحاولة.',
    'network-request-failed' => 'تحقق من اتصال الإنترنت ثم أعد المحاولة.',
    'not-admin' => 'هذا الحساب لا يملك صلاحية الأدمن.',
    _ => 'تعذر تسجيل الدخول. راجع إعدادات Firebase.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دخول الأدمن')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 46,
                        color: AppConstants.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'إدارة السيارات',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) =>
                            value == null || !value.contains('@')
                            ? 'أدخل بريدًا إلكترونيًا صحيحًا.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _passwordVisible
                                ? 'إخفاء كلمة المرور'
                                : 'إظهار كلمة المرور',
                            onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'أدخل كلمة المرور.'
                            : null,
                        onFieldSubmitted: (_) => _busy ? null : _signIn(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFB33A36)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _busy ? null : _signIn,
                        icon: _busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login_rounded),
                        label: Text(_busy ? 'جارٍ التحقق...' : 'تسجيل الدخول'),
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
