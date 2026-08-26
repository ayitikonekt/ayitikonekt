import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../../../core/localization/app_locale_provider.dart';
import '../../../shared/widgets/app_back_button.dart';

class RegisterScreen extends StatefulWidget {
  final String country;
  final String language;

  const RegisterScreen({
    super.key,
    this.country = 'Chile',
    this.language = 'Español',
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();

  bool _usePhone = false;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  late String _country;

  String? _verificationId;

  // Países disponibles en AyitiKonekt.
  static const List<String> _countries = [
    'Chile',
    'Haití',
    'República Dominicana',
    'México',
    'Estados Unidos',
    'Canadá',
    'Francia',
    'Brasil',
  ];

  @override
  void initState() {
    super.initState();

    // Conservamos el país seleccionado anteriormente.
    _country = widget.country;

    // Protección por si algún país antiguo no está en la lista.
    if (!_countries.contains(_country)) {
      _country = 'Chile';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToSignInEntry() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _registerWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final authProvider = context.read<AuthProvider>();

      await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name:
            '${_nameController.text.trim()} ${_lastNameController.text.trim()}'
                .trim(),
        phone: '',
        country: _country,
        language: widget.language,
      );

      // Firebase inicia sesión automáticamente al crear la cuenta.
      // La cerramos para que el usuario confirme sus credenciales en login.
      await authProvider.logout();
      _goToSignInEntry();
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
      final authProvider = context.read<AuthProvider>();

      await authProvider.signInWithPhoneCode(
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
        name: _nameController.text.trim(),
        country: _country,
        language: widget.language,
      );

      await authProvider.logout();
      _goToSignInEntry();
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    appBar: AppBar(
      leadingWidth: 112,
      leading: const AppBackButton(
        showWhenCannotPop: false,
        foregroundColor: Colors.white,
      ),
      title: Text(context.tr('createAccount')),
      backgroundColor: const Color(0xFF0646D8),
      foregroundColor: Colors.white,
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth < 600 ? 20 : 40,
            vertical: constraints.maxHeight < 720 ? 16 : 28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _registerField(
                      controller: _nameController,
                      hint: context.tr('name'),
                      capitalization: TextCapitalization.words,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? context.tr('enterName')
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _registerField(
                      controller: _lastNameController,
                      hint: context.tr('lastName'),
                      capitalization: TextCapitalization.words,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? context.tr('enterLastName')
                          : null,
                    ),
                    const SizedBox(height: 14),
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
                          : (selection) => setState(() {
                              _usePhone = selection.first;
                              _verificationId = null;
                              _codeController.clear();
                            }),
                    ),
                    const SizedBox(height: 14),
                    if (_usePhone) ...[
                      _registerField(
                        controller: _phoneController,
                        hint: '${context.tr('phone')} (+56 9 1234 5678)',
                        keyboardType: TextInputType.phone,
                        validator: (value) =>
                            value == null || !value.trim().startsWith('+')
                            ? context.tr('internationalPhone')
                            : null,
                      ),
                      if (_verificationId != null) ...[
                        const SizedBox(height: 14),
                        _registerField(
                          controller: _codeController,
                          hint: context.tr('smsCode'),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ] else ...[
                      _registerField(
                        controller: _emailController,
                        hint: context.tr('emailAddress'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            value == null || !value.contains('@')
                            ? context.tr('invalidEmail')
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _passwordField(
                        controller: _passwordController,
                        hint: context.tr('password'),
                        obscure: _obscurePassword,
                        onToggle: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        validator: (value) => value == null || value.length < 6
                            ? context.tr('minPassword')
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _passwordField(
                        controller: _confirmPasswordController,
                        hint: context.tr('confirmPassword'),
                        obscure: _obscureConfirmation,
                        onToggle: () => setState(
                          () => _obscureConfirmation = !_obscureConfirmation,
                        ),
                        validator: (value) => value != _passwordController.text
                            ? context.tr('passwordsMismatch')
                            : null,
                      ),
                    ],
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _country,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.tr('country'),
                      ),
                      items: _countries
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _country = value!),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading
                          ? null
                          : _usePhone
                          ? (_verificationId == null
                                ? _requestPhoneCode
                                : _verifyPhoneCode)
                          : _registerWithEmail,
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
                                  ? context.tr('verifyCreate')
                                  : context.tr('createAccount'),
                            ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            context.tr('orContinueWith'),
                            style: const TextStyle(color: Color(0xFF667085)),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _providerButton('G', 'Google'),
                        const SizedBox(width: 24),
                        _providerButton('●', 'Apple'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(context.tr('existingAccountQuestion')),
                        TextButton(
                          onPressed: _loading ? null : _goToSignInEntry,
                          child: Text(context.tr('signIn')),
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

  Widget _registerField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    textCapitalization: capitalization,
    decoration: InputDecoration(hintText: hint),
    validator: validator,
  );

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) => TextFormField(
    controller: controller,
    obscureText: obscure,
    decoration: InputDecoration(
      hintText: hint,
      suffixIcon: IconButton(
        tooltip: 'Mostrar u ocultar contraseña',
        onPressed: onToggle,
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
    validator: validator,
  );

  Widget _providerButton(String mark, String provider) => Semantics(
    label: provider,
    button: true,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(72, 52),
        backgroundColor: Colors.white,
      ),
      onPressed: _loading
          ? null
          : () => _showError(
              'El registro con $provider requiere configurar ese proveedor en Firebase.',
            ),
      child: Text(
        mark,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
    ),
  );
}
