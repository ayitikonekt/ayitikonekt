import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/app_back_button.dart';

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  Future<void> _call(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo iniciar la llamada al $number.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        leadingWidth: 112,
        leading: const AppBackButton(
          showWhenCannotPop: false,
          foregroundColor: Colors.white,
        ),
        backgroundColor: const Color(0xFFF20D1B),
        foregroundColor: Colors.white,
        title: const Text('SOS y emergencias'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth < 600 ? 16 : 24,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.health_and_safety_rounded,
                      size: 76,
                      color: Color(0xFFF20D1B),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '¿Necesitas ayuda inmediata?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Selecciona el servicio de emergencia que necesitas en Chile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF667085), height: 1.4),
                    ),
                    const SizedBox(height: 26),
                    _EmergencyButton(
                      icon: Icons.local_police_outlined,
                      label: 'Carabineros',
                      number: '133',
                      color: const Color(0xFF0646D8),
                      onPressed: () => _call(context, '133'),
                    ),
                    const SizedBox(height: 12),
                    _EmergencyButton(
                      icon: Icons.local_fire_department_outlined,
                      label: 'Bomberos',
                      number: '132',
                      color: const Color(0xFFF20D1B),
                      onPressed: () => _call(context, '132'),
                    ),
                    const SizedBox(height: 12),
                    _EmergencyButton(
                      icon: Icons.medical_services_outlined,
                      label: 'Ambulancia SAMU',
                      number: '131',
                      color: const Color(0xFF168447),
                      onPressed: () => _call(context, '131'),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Usa estos números solamente ante una emergencia real.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String number;
  final Color color;
  final VoidCallback onPressed;

  const _EmergencyButton({
    required this.icon,
    required this.label,
    required this.number,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: .12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              number,
              style: TextStyle(
                color: color,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.call_rounded, color: color),
          ],
        ),
      ),
    ),
  );
}
