import 'package:flutter/material.dart';

import '../../../core/localization/app_locale_provider.dart';
import '../../../shared/widgets/app_back_button.dart';
import 'all_products_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static const _salesCategories = <({
    String title,
    IconData icon,
    Color color,
  })>[
    (title: 'Vehículos', icon: Icons.directions_car, color: Colors.blue),
    (title: 'Electrónica', icon: Icons.devices, color: Colors.indigo),
    (title: 'Celulares', icon: Icons.phone_android, color: Colors.deepPurple),
    (title: 'Computadores', icon: Icons.computer, color: Colors.blueGrey),
    (title: 'Vivienda', icon: Icons.home, color: Colors.lightBlue),
    (title: 'Ropa', icon: Icons.checkroom, color: Colors.red),
    (title: 'Zapatos', icon: Icons.ice_skating, color: Colors.deepOrange),
    (title: 'Muebles', icon: Icons.chair, color: Colors.brown),
    (title: 'Electrodomésticos', icon: Icons.kitchen, color: Colors.blueGrey),
    (title: 'Mascotas', icon: Icons.pets, color: Colors.orange),
    (title: 'Otros', icon: Icons.more_horiz, color: Colors.grey),
  ];

  static const _serviceCategories = <({
    String title,
    IconData icon,
    Color color,
  })>[
    (title: 'Empleos', icon: Icons.work, color: Colors.green),
    (title: 'Servicios', icon: Icons.handyman, color: Colors.orange),
    (title: 'Construcción', icon: Icons.construction, color: Colors.amber),
    (title: 'Electricista', icon: Icons.electrical_services, color: Colors.orange),
    (title: 'Gasfiter', icon: Icons.plumbing, color: Colors.blue),
    (title: 'Pintor', icon: Icons.format_paint, color: Colors.deepPurple),
  ];

  void _openCategory(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllProductsScreen(
          category: category,
          screenTitle: category,
        ),
      ),
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
        title: Text(
          context.tr('categories'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0646D8),
        foregroundColor: Colors.white,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            children: [
          _CategoryHeader(context.tr('buyAndSell')),
          ..._salesCategories.map(
            (item) => _CategoryTile(
              title: item.title,
              icon: item.icon,
              color: item.color,
              onTap: () => _openCategory(context, item.title),
            ),
          ),
          const SizedBox(height: 20),
          _CategoryHeader(context.tr('jobsAndServices')),
          ..._serviceCategories.map(
            (item) => _CategoryTile(
              title: item.title,
              icon: item.icon,
              color: item.color,
              onTap: () => _openCategory(context, item.title),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;

  const _CategoryHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: .7,
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 7),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
