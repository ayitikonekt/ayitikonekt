import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_locale_provider.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../home/presentation/main_navigation.dart';
import '../../splash/presentation/widgets/brand_logo.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final String country;
  final String language;

  const LoginScreen({
    super.key,
    this.country = 'Chile',
    this.language = 'Español',
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  bool _usePhone = false;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _verificationId;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
      (route) => false,
    );
  }

  String _defaultCityFor(String country) => switch (country) {
    'Estados Unidos' => 'New York',
    'Canadá' => 'Montréal',
    'República Dominicana' => 'Santo Domingo',
    'Haití' => 'Puerto Príncipe',
    'Francia' => 'Paris',
    'México' => 'Ciudad de México',
    'Brasil' => 'São Paulo',
    _ => 'Santiago',
  };

  Future<void> _applySelectedPreferences() async {
    final authUser = context.read<AuthProvider>().user;
    if (authUser == null) return;
    final userService = UserService();
    final profile = await userService.getUser(authUser.uid);
    if (profile == null) return;

    await userService.updateUser(
      profile.copyWith(
        country: widget.country,
        language: widget.language,
        city: _defaultCityFor(widget.country),
        address: '',
      ),
    );
    if (!mounted) return;
    context.read<AppLocaleProvider>().selectLanguageName(widget.language);
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await context.read<AuthProvider>().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _applySelectedPreferences();
      _goToHome();
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestPhoneCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await context.read<AuthProvider>().requestPhoneCode(
        phoneNumber: _phoneController.text.trim(),
        onCodeSent: (verificationId) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _loading = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.tr('smsSent'))));
        },
        onError: _showError,
      );
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted && _verificationId == null) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _verifyPhoneCode() async {
    if (_codeController.text.trim().length < 6 || _verificationId == null) {
      _showError(context.tr('sixDigits'));
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().signInWithPhoneCode(
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
        country: widget.country,
        language: widget.language,
      );
      await _applySelectedPreferences();
      _goToHome();
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ForgotPasswordScreen(initialEmail: _emailController.text.trim()),
      ),
    );
  }

  void _selectLoginMethod(bool usePhone) {
    setState(() {
      _usePhone = usePhone;
      _verificationId = null;
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leadingWidth: 112,
        leading: const AppBackButton(showWhenCannotPop: false),
        title: Text(context.tr('signIn')),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 650;
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth < 600 ? 22 : 40,
                vertical: compact ? 16 : 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: BrandLogo(size: compact ? 64 : 78)),
                        SizedBox(height: compact ? 18 : 28),
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(
                              value: false,
                              icon: const Icon(Icons.email_outlined),
                              label: Text(context.tr('email')),
                            ),
                            ButtonSegment(
                              value: true,
                              icon: const Icon(Icons.phone_outlined),
                              label: Text(context.tr('phone')),
                            ),
                          ],
                          selected: {_usePhone},
                          onSelectionChanged: _loading
                              ? null
                              : (selection) =>
                                    _selectLoginMethod(selection.first),
                        ),
                        const SizedBox(height: 18),
                        if (_usePhone) ...[
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            decoration: InputDecoration(
                              labelText: context.tr('phone'),
                              hintText: '+56 9 1234 5678',
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                            validator: (value) =>
                                value == null || !value.trim().startsWith('+')
                                ? context.tr('internationalPhone')
                                : null,
                          ),
                          if (_verificationId != null) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              decoration: InputDecoration(
                                labelText: context.tr('smsCode'),
                                prefixIcon: const Icon(Icons.password_rounded),
                              ),
                            ),
                          ],
                        ] else ...[
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              labelText: context.tr('emailAddress'),
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            validator: (value) =>
                                value == null || !value.contains('@')
                                ? context.tr('invalidEmail')
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: context.tr('password'),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: context.tr('togglePassword'),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? context.tr('enterPassword')
                                : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _loading ? null : _resetPassword,
                              child: Text(context.tr('forgotPassword')),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _loading
                                ? null
                                : _usePhone
                                ? (_verificationId == null
                                      ? _requestPhoneCode
                                      : _verifyPhoneCode)
                                : _loginWithEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0646D8),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _usePhone && _verificationId == null
                                        ? context.tr('sendSms')
                                        : _usePhone
                                        ? context.tr('verifySignIn')
                                        : context.tr('signIn'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: compact ? 16 : 24),
                        Center(
                          child: Text(
                            context.tr('newAccountQuestion'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                                },
                          child: Text(
                            context.tr('createAccount'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
