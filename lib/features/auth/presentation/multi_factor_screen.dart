import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_locale_provider.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../providers/auth_provider.dart';
import '../services/multi_factor_service.dart';

class MultiFactorEnrollmentScreen extends StatefulWidget {
  const MultiFactorEnrollmentScreen({super.key});

  @override
  State<MultiFactorEnrollmentScreen> createState() =>
      _MultiFactorEnrollmentScreenState();
}

class _MultiFactorEnrollmentScreenState
    extends State<MultiFactorEnrollmentScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _service = MultiFactorService();

  bool _loading = true;
  bool _enrolled = false;
  String? _phone;
  String? _verificationId;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!MultiFactorService.isSupportedMobilePlatform) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final adminOnlyMessage = context.tr('mfaAdminOnly');
    try {
      final role = await _service.administrativeRole(forceRefresh: true);
      if (role == null) throw StateError(adminOnlyMessage);
      final factors = await _service.enrolledFactors();
      final phoneFactors = factors.whereType<PhoneMultiFactorInfo>().toList();
      if (!mounted) return;
      setState(() {
        _enrolled = phoneFactors.isNotEmpty;
        _phone = phoneFactors.isEmpty ? null : phoneFactors.first.phoneNumber;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (!phone.startsWith('+') || phone.length < 8) {
      setState(() => _error = context.tr('internationalPhone'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _service.startEnrollment(
        phoneNumber: phone,
        verificationCompleted: (credential) =>
            unawaited(_finishWithCredential(credential)),
        verificationFailed: (error) {
          if (!mounted) return;
          setState(() {
            _error = error.message ?? error.code;
            _loading = false;
          });
        },
        codeSent: (verificationId, _) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _loading = false;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (mounted && _verificationId == null) {
            setState(() => _verificationId = verificationId);
          }
        },
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted && _verificationId == null && !_enrolled) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _finishWithCredential(PhoneAuthCredential credential) async {
    setState(() => _loading = true);
    try {
      await _service.finishEnrollmentWithCredential(credential);
      await _completeEnrollment();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (_verificationId == null || code.length != 6) {
      setState(() => _error = context.tr('sixDigits'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _service.finishEnrollment(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await _completeEnrollment();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _completeEnrollment() async {
    final factors = await _service.enrolledFactors();
    final phoneFactors = factors.whereType<PhoneMultiFactorInfo>().toList();
    if (!mounted) return;
    setState(() {
      _enrolled = true;
      _phone = phoneFactors.isEmpty ? null : phoneFactors.first.phoneNumber;
      _loading = false;
      _verificationId = null;
      _codeController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('mfaEnrollmentComplete'))),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),
    appBar: AppBar(
      leadingWidth: 112,
      leading: const AppBackButton(foregroundColor: Colors.white),
      title: Text(context.tr('mfaAdminSecurity')),
      centerTitle: true,
      backgroundColor: const Color(0xFF0646D8),
      foregroundColor: Colors.white,
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(
                Icons.phonelink_lock_rounded,
                size: 64,
                color: Color(0xFF0646D8),
              ),
              const SizedBox(height: 18),
              Text(
                context.tr('mfaTitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                !MultiFactorService.isSupportedMobilePlatform
                    ? context.tr('mfaMobileOnly')
                    : _enrolled
                    ? context.trWith('mfaEnabledFor', {'phone': _phone ?? ''})
                    : context.tr('mfaConsent'),
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.5, color: Color(0xFF475467)),
              ),
              if (_loading) ...[
                const SizedBox(height: 28),
                const Center(child: CircularProgressIndicator()),
              ] else if (_error != null) ...[
                const SizedBox(height: 18),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              if (!_loading &&
                  MultiFactorService.isSupportedMobilePlatform &&
                  !_enrolled) ...[
                const SizedBox(height: 24),
                TextField(
                  controller: _phoneController,
                  enabled: _verificationId == null,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: InputDecoration(
                    labelText: context.tr('mfaPhoneLabel'),
                    hintText: '+56 9 1234 5678',
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                if (_verificationId != null) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    decoration: InputDecoration(
                      labelText: context.tr('smsCode'),
                      prefixIcon: const Icon(Icons.password_rounded),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _verificationId == null
                        ? _sendCode
                        : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0646D8),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _verificationId == null
                          ? context.tr('mfaSendCode')
                          : context.tr('mfaEnable'),
                    ),
                  ),
                ),
              ],
              if (_enrolled) ...[
                const SizedBox(height: 20),
                Text(
                  context.tr('mfaSignInAgain'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class MultiFactorChallengeScreen extends StatefulWidget {
  const MultiFactorChallengeScreen({super.key, required this.exception});

  final FirebaseAuthMultiFactorException exception;

  @override
  State<MultiFactorChallengeScreen> createState() =>
      _MultiFactorChallengeScreenState();
}

class _MultiFactorChallengeScreenState
    extends State<MultiFactorChallengeScreen> {
  final _codeController = TextEditingController();
  final _service = MultiFactorService();
  String? _verificationId;
  String? _phone;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_sendChallenge());
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendChallenge() async {
    if (!MultiFactorService.isSupportedMobilePlatform) {
      if (mounted) {
        setState(() {
          _error = context.tr('mfaMobileOnly');
          _loading = false;
        });
      }
      return;
    }
    PhoneMultiFactorInfo? phoneFactor;
    for (final factor in widget.exception.resolver.hints) {
      if (factor is PhoneMultiFactorInfo) {
        phoneFactor = factor;
        break;
      }
    }
    if (phoneFactor == null) {
      setState(() {
        _error = context.tr('mfaNoPhoneFactor');
        _loading = false;
      });
      return;
    }
    _phone = phoneFactor.phoneNumber;
    try {
      await _service.startSignInChallenge(
        resolver: widget.exception.resolver,
        factor: phoneFactor,
        verificationCompleted: (credential) =>
            unawaited(_completeWithCredential(credential)),
        verificationFailed: (error) {
          if (!mounted) return;
          setState(() {
            _error = error.message ?? error.code;
            _loading = false;
          });
        },
        codeSent: (verificationId, _) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _loading = false;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (mounted && _verificationId == null) {
            setState(() => _verificationId = verificationId);
          }
        },
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _completeWithCredential(PhoneAuthCredential credential) async {
    setState(() => _loading = true);
    try {
      await context
          .read<AuthProvider>()
          .completeMultiFactorSignInWithCredential(
            resolver: widget.exception.resolver,
            credential: credential,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (_verificationId == null || code.length != 6) {
      setState(() => _error = context.tr('sixDigits'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().completeMultiFactorSignIn(
        resolver: widget.exception.resolver,
        verificationId: _verificationId!,
        smsCode: code,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),
    appBar: AppBar(
      leadingWidth: 112,
      leading: const AppBackButton(foregroundColor: Colors.white),
      title: Text(context.tr('mfaVerification')),
      centerTitle: true,
      backgroundColor: const Color(0xFF0646D8),
      foregroundColor: Colors.white,
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(
                Icons.sms_outlined,
                size: 60,
                color: Color(0xFF0646D8),
              ),
              const SizedBox(height: 18),
              Text(
                context.trWith('mfaCodeSentTo', {'phone': _phone ?? ''}),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                enabled: !_loading && _verificationId != null,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                decoration: InputDecoration(labelText: context.tr('smsCode')),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading || _verificationId == null
                      ? null
                      : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0646D8),
                    foregroundColor: Colors.white,
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
                      : Text(context.tr('mfaVerify')),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
