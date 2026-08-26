import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_locale_provider.dart';
import '../providers/marketplace_provider.dart';

class ProductFilterScreen extends StatefulWidget {
  const ProductFilterScreen({super.key});

  @override
  State<ProductFilterScreen> createState() => _ProductFilterScreenState();
}

class _ProductFilterScreenState extends State<ProductFilterScreen> {
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  late String _category;
  late String _type;
  late String _location;
  late String _sort;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MarketplaceProvider>();
    _category = provider.selectedCategory;
    _type = provider.selectedType;
    _location = provider.selectedLocation;
    _sort = provider.selectedSort;
    _minPriceController.text = _formatPrice(provider.minPrice);
    _maxPriceController.text = _formatPrice(provider.maxPrice);
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  String _formatPrice(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  double? _parsePrice(String value) {
    final normalized = value.trim().replaceAll('.', '').replaceAll(',', '.');
    return normalized.isEmpty ? null : double.tryParse(normalized);
  }

  void _clear() {
    context.read<MarketplaceProvider>().clearFilters();
    setState(() {
      _category = 'Todas';
      _type = 'Todos';
      _location = 'Todas';
      _sort = 'default';
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  void _apply() {
    final minPrice = _parsePrice(_minPriceController.text);
    final maxPrice = _parsePrice(_maxPriceController.text);
    if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('invalidPriceRange'))));
      return;
    }

    context.read<MarketplaceProvider>().applyFilters(
      category: _category,
      type: _type,
      location: _location,
      sort: _sort,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MarketplaceProvider>();
    final categories =
        <String>{
          'Todas',
          ...provider.allProducts.map((product) => product.category),
        }.toList()..sort((a, b) {
          if (a == 'Todas') return -1;
          if (b == 'Todas') return 1;
          return a.compareTo(b);
        });
    final locations =
        <String>{
          'Todas',
          ...provider.allProducts.map((product) => product.city),
        }.toList()..sort((a, b) {
          if (a == 'Todas') return -1;
          if (b == 'Todas') return 1;
          return a.compareTo(b);
        });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0646D8),
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          tooltip: context.tr('close'),
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(
          context.tr('filters'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _clear,
            child: Text(
              context.tr('clear'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4E7EC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label(context.tr('category')),
                    DropdownButtonFormField<String>(
                      initialValue: categories.contains(_category)
                          ? _category
                          : 'Todas',
                      isExpanded: true,
                      decoration: const InputDecoration(),
                      items: categories
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(
                                value == 'Todas'
                                    ? context.tr('allCategories')
                                    : value,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _category = value!),
                    ),
                    const SizedBox(height: 16),
                    _label(context.tr('type')),
                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(),
                      items: [
                        DropdownMenuItem(
                          value: 'Todos',
                          child: Text(context.tr('allMasculine')),
                        ),
                        DropdownMenuItem(
                          value: 'Productos',
                          child: Text(context.tr('products')),
                        ),
                        DropdownMenuItem(
                          value: 'Servicios',
                          child: Text(context.tr('services')),
                        ),
                      ],
                      onChanged: (value) => setState(() => _type = value!),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _typeButton('Productos')),
                        const SizedBox(width: 10),
                        Expanded(child: _typeButton('Servicios')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _label(context.tr('price')),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: context.tr('from'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: context.tr('to'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _label(context.tr('location')),
                    DropdownButtonFormField<String>(
                      initialValue: locations.contains(_location)
                          ? _location
                          : 'Todas',
                      isExpanded: true,
                      decoration: const InputDecoration(),
                      items: locations
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(
                                value == 'Todas'
                                    ? context.tr('allTowns')
                                    : value,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _location = value!),
                    ),
                    const SizedBox(height: 16),
                    _label(context.tr('sortBy')),
                    DropdownButtonFormField<String>(
                      initialValue: _sort,
                      isExpanded: true,
                      decoration: const InputDecoration(),
                      items: [
                        DropdownMenuItem(
                          value: 'default',
                          child: Text(context.tr('defaultSort')),
                        ),
                        DropdownMenuItem(
                          value: 'newest',
                          child: Text(context.tr('newest')),
                        ),
                        DropdownMenuItem(
                          value: 'oldest',
                          child: Text(context.tr('oldest')),
                        ),
                        DropdownMenuItem(
                          value: 'priceAsc',
                          child: Text(context.tr('priceLowHigh')),
                        ),
                        DropdownMenuItem(
                          value: 'priceDesc',
                          child: Text(context.tr('priceHighLow')),
                        ),
                      ],
                      onChanged: (value) => setState(() => _sort = value!),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _apply,
                      child: Text(
                        context.tr('applyFilters'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
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

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
  );

  Widget _typeButton(String value) {
    final selected = _type == value;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? const Color(0xFF0646D8) : Colors.white,
        foregroundColor: selected ? Colors.white : const Color(0xFF1F2937),
        side: BorderSide(
          color: selected ? const Color(0xFF0646D8) : const Color(0xFFD0D5DD),
        ),
      ),
      onPressed: () => setState(() => _type = value),
      child: Text(context.tr(value == 'Productos' ? 'products' : 'services')),
    );
  }
}
