import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_locale_provider.dart';
import 'welcome_screen.dart';



class LanguageSelectionScreen extends StatefulWidget {
  final String country;

  const LanguageSelectionScreen({
    super.key,
    required this.country,
  });

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends State<LanguageSelectionScreen> {
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    final preferredCode = switch (widget.country) {
      'Estados Unidos' => 'en',
      'Canadá' => 'en',
      'Haití' => 'ht',
      'Francia' => 'fr',
      'Brasil' => 'pt',
      _ => 'es',
    };
    for (final language in _languages) {
      if (language['code'] == preferredCode) {
        _selectedLanguage = language['name'];
        break;
      }
    }
  }

  List<Map<String, String>> get _languages {
    switch (widget.country) {
      case 'Estados Unidos':
        return [
          {
            'name': 'Kreyòl Ayisyen',
            'code': 'ht',
          },
          {
            'name': 'English',
            'code': 'en',
          },
          {
            'name': 'Español',
            'code': 'es',
          },
        ];

      case 'Canadá':
        return [
          {
            'name': 'Kreyòl Ayisyen',
            'code': 'ht',
          },
          {
            'name': 'English',
            'code': 'en',
          },
          {
            'name': 'Français',
            'code': 'fr',
          },
        ];

      case 'Haití':
        return [
          {
            'name': 'Kreyòl Ayisyen',
            'code': 'ht',
          },
          {
            'name': 'Français',
            'code': 'fr',
          },
        ];

      case 'Francia':
        return [
          {
            'name': 'Kreyòl Ayisyen',
            'code': 'ht',
          },
          {
            'name': 'Français',
            'code': 'fr',
          },
          {
            'name': 'English',
            'code': 'en',
          },
        ];

      case 'Brasil':
        return [
          {
            'name': 'Kreyòl Ayisyen',
            'code': 'ht',
          },
          {
            'name': 'Português',
            'code': 'pt',
          },
        ];

      case 'Chile':
      case 'República Dominicana':
      case 'México':
      default:
        return [
          {
            'name': 'Kreyòl Ayisyen',
            'code': 'ht',
          },
          {
            'name': 'Español',
            'code': 'es',
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 620;
            final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 24.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        SizedBox(height: compact ? 28 : 72),
                        const Text(
                          'Chwazi lang ou /\nElige tu idioma',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF151B2A),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Ou kapab chanje li pita nan\nanviwònman yo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: Color(0xFF303642),
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 28 : 52),
                        ..._languages.map((language) {
                          final name = language['name']!;
                          final code = language['code']!;
                          final selected = _selectedLanguage == name;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Semantics(
                              button: true,
                              selected: selected,
                              label: name,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => setState(
                                  () => _selectedLanguage = name,
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  height: 62,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFFCBD5E1)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x0F0F172A),
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      _FlagIcon(code: code),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        selected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        size: 23,
                                        color: selected
                                            ? const Color(0xFF0B3BC1)
                                            : const Color(0xFFD1D5DB),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        const Spacer(),
                        const SizedBox(height: 34),
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                 onPressed: _selectedLanguage == null
    ? null
    : () {
        final selected = _languages.firstWhere(
          (item) => item['name'] == _selectedLanguage,
        );
        context.read<AppLocaleProvider>().selectLanguage(
          code: selected['code']!,
          name: selected['name']!,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomeScreen(
              country: widget.country,
              language: _selectedLanguage!,
            ),
          ),
        );
      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF073EC5),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD1D5DB),
                    elevation: 4,
                    shadowColor: const Color(0x55073EC5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                        ),
                        SizedBox(height: compact ? 18 : 30),
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

class _FlagIcon extends StatelessWidget {
  final String code;

  const _FlagIcon({required this.code});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CustomPaint(
        size: const Size(34, 25),
        painter: _FlagPainter(code),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  final String code;

  const _FlagPainter(this.code);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rect = Offset.zero & size;

    switch (code) {
      case 'ht':
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height / 2), paint..color = const Color(0xFF00209F));
        canvas.drawRect(Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2), paint..color = const Color(0xFFD21034));
        canvas.drawRect(Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: 15, height: 11), paint..color = Colors.white);
        _drawHaitiCoatOfArms(canvas, size, paint);
        break;
      case 'es':
        canvas.drawRect(rect, paint..color = Colors.white);
        canvas.drawRect(Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2), paint..color = const Color(0xFFD52B1E));
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width * .36, size.height / 2), paint..color = const Color(0xFF0039A6));
        _drawStar(canvas, Offset(size.width * .18, size.height * .25), 3.7, paint..color = Colors.white);
        break;
      case 'fr':
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width / 3, size.height), paint..color = const Color(0xFF0055A4));
        canvas.drawRect(Rect.fromLTWH(size.width / 3, 0, size.width / 3, size.height), paint..color = Colors.white);
        canvas.drawRect(Rect.fromLTWH(size.width * 2 / 3, 0, size.width / 3, size.height), paint..color = const Color(0xFFEF4135));
        break;
      case 'pt':
        canvas.drawRect(rect, paint..color = const Color(0xFF009C3B));
        final path = Path()
          ..moveTo(size.width / 2, 3)
          ..lineTo(size.width - 4, size.height / 2)
          ..lineTo(size.width / 2, size.height - 3)
          ..lineTo(4, size.height / 2)
          ..close();
        canvas.drawPath(path, paint..color = const Color(0xFFFFDF00));
        canvas.drawCircle(Offset(size.width / 2, size.height / 2), 4.5, paint..color = const Color(0xFF002776));
        break;
      default:
        canvas.drawRect(rect, paint..color = Colors.white);
        for (var i = 0; i < 7; i++) {
          canvas.drawRect(Rect.fromLTWH(0, i * size.height / 7, size.width, size.height / 14), paint..color = const Color(0xFFB22234));
        }
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width * .43, size.height * .54), paint..color = const Color(0xFF3C3B6E));
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -1.5708 + i * 0.62832;
      final r = i.isEven ? radius : radius * .42;
      final point = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHaitiCoatOfArms(Canvas canvas, Size size, Paint paint) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    canvas.drawRect(
      Rect.fromCenter(center: Offset(centerX, centerY + 3.4), width: 8.5, height: 1.5),
      paint..color = const Color(0xFF2F6B3C),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, centerY + 2.5), width: 4.5, height: 1.8),
      paint..color = const Color(0xFFC89B3C),
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(centerX, centerY - .3), width: 1.15, height: 6.2),
      paint..color = const Color(0xFF8B5A2B),
    );

    for (final end in [
      Offset(centerX - 3.5, centerY - 3.1),
      Offset(centerX - 2.4, centerY - 4.2),
      Offset(centerX, centerY - 4.7),
      Offset(centerX + 2.4, centerY - 4.2),
      Offset(centerX + 3.5, centerY - 3.1),
    ]) {
      canvas.drawLine(
        Offset(centerX, centerY - 2.6),
        end,
        paint
          ..color = const Color(0xFF168447)
          ..strokeWidth = 1.05
          ..strokeCap = StrokeCap.round,
      );
    }

    paint
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(centerX - 1.2, centerY + 1.5), Offset(centerX - 5.5, centerY + 3), paint..color = const Color(0xFFB98224));
    canvas.drawLine(Offset(centerX + 1.2, centerY + 1.5), Offset(centerX + 5.5, centerY + 3), paint..color = const Color(0xFFB98224));
    canvas.drawLine(Offset(centerX - 1.8, centerY + 1.2), Offset(centerX - 5, centerY - 2.2), paint..color = const Color(0xFF003DA5));
    canvas.drawLine(Offset(centerX + 1.8, centerY + 1.2), Offset(centerX + 5, centerY - 2.2), paint..color = const Color(0xFFD21034));
  }

  @override
  bool shouldRepaint(covariant _FlagPainter oldDelegate) => oldDelegate.code != code;
}
