import 'package:flutter/material.dart';

import '../../../shared/widgets/app_back_button.dart';
import 'create_product_screen.dart';

class PublicationTypeScreen extends StatelessWidget {
  const PublicationTypeScreen({super.key});

  void _openForm(BuildContext context, String listingType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateProductScreen(listingType: listingType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0646D8),
      foregroundColor: Colors.white,
      leadingWidth: 112,
      leading: const AppBackButton(
        showWhenCannotPop: false,
        foregroundColor: Colors.white,
      ),
      title: const Text(
        '¿Qué quieres publicar?',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Elige el tipo de publicación',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Te mostraremos un formulario adaptado a lo que ofreces.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF667085), fontSize: 16),
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cards = [
                      _TypeCard(
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFF0646D8),
                        title: 'Producto',
                        subtitle: 'Vende algo que tienes.',
                        details: 'Precio, estado, categoría, fotos y ubicación.',
                        onTap: () => _openForm(context, 'product'),
                      ),
                      _TypeCard(
                        icon: Icons.handyman_outlined,
                        color: const Color(0xFFF28C00),
                        title: 'Servicio',
                        subtitle: 'Ofrece tu trabajo o habilidad.',
                        details: 'Especialidad, zona, disponibilidad y trabajos.',
                        onTap: () => _openForm(context, 'service'),
                      ),
                    ];
                    if (constraints.maxWidth < 650) {
                      return Column(
                        children: [cards.first, const SizedBox(height: 16), cards.last],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: cards.first),
                        const SizedBox(width: 20),
                        Expanded(child: cards.last),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String details;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 34),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(details, style: const TextStyle(color: Color(0xFF667085), height: 1.4)),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.arrow_forward_rounded, color: color),
            ),
          ],
        ),
      ),
    ),
  );
}
