import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/xfile_image.dart';

import '../../auth/providers/auth_provider.dart';
import '../../auth/services/user_service.dart';
import '../models/product_model.dart';
import '../providers/marketplace_provider.dart';
import '../services/storage_service.dart';

class CreateProductScreen extends StatefulWidget {
  final String listingType;

  const CreateProductScreen({super.key, this.listingType = 'product'});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController(text: 'Chile');
  final _addressController = TextEditingController();
  final _serviceAreaController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _picker = ImagePicker();
  final _storageService = StorageService();

  List<XFile> _selectedImages = [];
  bool _saving = false;
  String _category = 'Electrónica';
  String _condition = 'Usado';
  bool _priceNegotiable = false;

  bool get _isService => widget.listingType == 'service';

  static const _categories = [
    'Electrónica',
    'Celulares',
    'Computadores',
    'Vehículos',
    'Vivienda',
    'Ropa',
    'Zapatos',
    'Muebles',
    'Electrodomésticos',
    'Mascotas',
    'Otros',
  ];
  static const _serviceSpecialties = [
    'Gasfitería',
    'Electricidad',
    'Construcción',
    'Pintura',
    'Limpieza',
    'Jardinería',
    'Belleza',
    'Reparaciones',
    'Clases',
    'Transporte',
    'Tecnología',
    'Otros',
  ];
  static const _conditions = ['Nuevo', 'Usado', 'Reacondicionado'];

  @override
  void initState() {
    super.initState();
    if (_isService) _category = _serviceSpecialties.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _addressController.dispose();
    _serviceAreaController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty || !mounted) return;

    setState(() {
      _selectedImages = images.take(8).map((image) => image).toList();
    });
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;

    final priceText = _priceController.text
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final price = _priceNegotiable ? 0.0 : double.tryParse(priceText);
    final messenger = ScaffoldMessenger.of(context);
    final user = context.read<AuthProvider>().user;
    final marketplace = context.read<MarketplaceProvider>();

    if (price == null || (!_priceNegotiable && price <= 0)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Ingrese un precio válido.')),
      );
      return;
    }
    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Debe iniciar sesión para publicar.')),
      );
      return;
    }

    final userProfile = await UserService().getUser(user.uid);

    setState(() => _saving = true);
    final now = DateTime.now();
    final productId = now.microsecondsSinceEpoch.toString();

    try {
      final imageUrls = await Future.wait(
        _selectedImages.map(
          (image) => _storageService.uploadProductImage(
            file: image,
            productId: productId,
            ownerId: user.uid,
          ),
        ),
      );

      await marketplace.createProduct(
        ProductModel(
          id: productId,
          sellerId: user.uid,
          sellerName: userProfile != null
              ? '${userProfile.name} ${userProfile.lastName}'.trim()
              : user.displayName ?? 'Usuario',
          sellerEmail: userProfile?.email ?? user.email ?? '',
          sellerPhone: userProfile?.phone ?? user.phoneNumber ?? '',
          sellerPhoto: userProfile?.photo ?? user.photoURL ?? '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          category: _category,
          listingType: widget.listingType,
          priceNegotiable: _priceNegotiable,
          serviceArea: _serviceAreaController.text.trim(),
          availability: _availabilityController.text.trim(),
          condition: _isService ? 'No aplica' : _condition,
          country: _countryController.text.trim(),
          city: _cityController.text.trim(),
          address: _addressController.text.trim(),
          images: imageUrls,
          createdAt: now,
          updatedAt: now,
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isService
                ? 'Servicio publicado correctamente.'
                : 'Producto publicado correctamente.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0646D8),
      foregroundColor: Colors.white,
      centerTitle: false,
      leadingWidth: 112,
      leading: const AppBackButton(
        showWhenCannotPop: false,
        foregroundColor: Colors.white,
      ),
      title: Text(
        _isService ? 'Publicar servicio' : 'Publicar producto',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          tooltip: 'Cerrar',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, viewport) => SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: viewport.maxWidth < 600 ? 12 : 24,
            vertical: viewport.maxWidth < 600 ? 12 : 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Form(
                key: _formKey,
                child: LayoutBuilder(
                  builder: (context, content) {
                    final wide = content.maxWidth >= 720;
                    final photoPanel = _photoPanel();
                    final formPanel = _formPanel(wide);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 280, child: photoPanel),
                              const SizedBox(width: 24),
                              Expanded(child: formPanel),
                            ],
                          )
                        else ...[
                          photoPanel,
                          const SizedBox(height: 16),
                          formPanel,
                        ],
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: wide ? 300 : double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFED1C24),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(54),
                              ),
                              onPressed: _saving ? null : _publish,
                              child: _saving
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isService
                                          ? 'Publicar servicio'
                                          : 'Publicar producto',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _photoPanel() => _panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _saving ? null : _pickImages,
          child: Container(
            constraints: const BoxConstraints(minHeight: 150),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: _selectedImages.isEmpty
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: Color(0xFF0646D8),
                        size: 36,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Agregar fotos',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Máx. 8 fotos',
                        style: TextStyle(color: Color(0xFF667085)),
                      ),
                    ],
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedImages
                        .map(
                          (image) => ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: XFileImage(file: image),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _saving ? null : _pickImages,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text('Cambiar imágenes (${_selectedImages.length}/8)'),
          ),
        ],
      ],
    ),
  );

  Widget _formPanel(bool wide) => _panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(_isService ? 'Nombre del servicio' : 'Título del producto'),
        TextFormField(
          controller: _titleController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: _isService ? 'Ej. Reparación de gasfitería' : 'Ej. iPhone 15 Pro',
          ),
          validator: _required,
        ),
        const SizedBox(height: 14),
        if (_isService) ...[
          _label('Precio'),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _priceNegotiable,
            title: const Text('Precio a convenir'),
            subtitle: const Text('El cliente deberá consultar el valor.'),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (value) => setState(() => _priceNegotiable = value ?? false),
          ),
          if (!_priceNegotiable)
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'Ej. 25.000'),
              validator: _required,
            ),
        ] else
          _responsivePair(
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'Ej. 650.000'),
              validator: _required,
            ),
            'Precio',
            DropdownButtonFormField<String>(
              initialValue: _condition,
              isExpanded: true,
              decoration: const InputDecoration(),
              items: _conditions
                  .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) => setState(() => _condition = value!),
            ),
            'Condición',
            wide,
          ),
        const SizedBox(height: 14),
        _label(_isService ? 'Especialidad' : 'Categoría'),
        DropdownButtonFormField<String>(
          initialValue: _category,
          isExpanded: true,
          decoration: const InputDecoration(),
          items: (_isService ? _serviceSpecialties : _categories)
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) => setState(() => _category = value!),
        ),
        const SizedBox(height: 14),
        _label('Descripción'),
        TextFormField(
          controller: _descriptionController,
          minLines: 4,
          maxLines: 7,
          decoration: InputDecoration(
            hintText: _isService
                ? 'Explica qué trabajo realizas y qué incluye...'
                : 'Describe el producto, sus características y estado...',
          ),
          validator: _required,
        ),
        const SizedBox(height: 14),
        _label(_isService ? 'Ubicación base' : 'Ubicación aproximada'),
        _responsivePair(
          TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(hintText: 'Comuna o ciudad'),
            validator: _required,
          ),
          'Ciudad',
          TextFormField(
            controller: _countryController,
            decoration: const InputDecoration(hintText: 'País'),
            validator: _required,
          ),
          'País',
          wide,
        ),
        const SizedBox(height: 14),
        if (_isService) ...[
          _label('Zona donde atiende'),
          TextFormField(
            controller: _serviceAreaController,
            decoration: const InputDecoration(
              hintText: 'Ej. Santiago Centro, Providencia y comunas cercanas',
              prefixIcon: Icon(Icons.map_outlined),
            ),
            validator: _required,
          ),
          const SizedBox(height: 14),
          _label('Disponibilidad'),
          TextFormField(
            controller: _availabilityController,
            decoration: const InputDecoration(
              hintText: 'Ej. Lunes a sábado, de 09:00 a 18:00',
              prefixIcon: Icon(Icons.schedule_outlined),
            ),
            validator: _required,
          ),
        ] else ...[
          _label('Dirección (opcional)'),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              hintText: 'Referencia o dirección aproximada',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _panel({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE4E7EC)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D101828),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
  );

  Widget _responsivePair(
    Widget first,
    String firstLabel,
    Widget second,
    String secondLabel,
    bool wide,
  ) {
    final firstField = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_label(firstLabel), first],
    );
    final secondField = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_label(secondLabel), second],
    );

    if (!wide) {
      return Column(
        children: [firstField, const SizedBox(height: 14), secondField],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: firstField),
        const SizedBox(width: 16),
        Expanded(child: secondField),
      ],
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Este campo es obligatorio'
      : null;
}
