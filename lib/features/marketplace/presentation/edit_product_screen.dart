import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/xfile_image.dart';

import '../models/product_model.dart';
import '../providers/marketplace_provider.dart';
import '../services/storage_service.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;
  late final TextEditingController _addressController;
  late final TextEditingController _serviceAreaController;
  late final TextEditingController _availabilityController;

  late String _category;
  late String _condition;
  bool _saving = false;
  bool _pickingImages = false;
  late bool _priceNegotiable;

  bool get _isService => widget.product.isService;

  final _picker = ImagePicker();
  final StorageService _storageService = StorageService();

  final List<XFile> _selectedImages = [];
  List<String> _existingImages = [];

  static const _categories = [
    'Electrónica',
    'Celulares',
    'Computadores',
    'Vehículos',
    'Vivienda',
    'Empleos',
    'Servicios',
    'Construcción',
    'Electricista',
    'Gasfiter',
    'Pintor',
    'Ropa',
    'Zapatos',
    'Muebles',
    'Electrodomésticos',
    'Mascotas',
    'Otros',
    'Gasfitería',
    'Electricidad',
    'Pintura',
    'Limpieza',
    'Jardinería',
    'Belleza',
    'Reparaciones',
    'Clases',
    'Transporte',
    'Tecnología',
  ];

  static const _conditions = ['Nuevo', 'Usado', 'Reacondicionado'];

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.product.title);

    _descriptionController = TextEditingController(
      text: widget.product.description,
    );

    _priceController = TextEditingController(
      text: widget.product.price.toString(),
    );

    _cityController = TextEditingController(text: widget.product.city);

    _countryController = TextEditingController(text: widget.product.country);

    _addressController = TextEditingController(text: widget.product.address);
    _serviceAreaController = TextEditingController(
      text: widget.product.serviceArea,
    );
    _availabilityController = TextEditingController(
      text: widget.product.availability,
    );

    _category = widget.product.category;
    _condition = widget.product.condition;
    _priceNegotiable = widget.product.priceNegotiable;
    _existingImages = List<String>.from(widget.product.images);
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

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }

    return null;
  }

  Future<void> _pickImages() async {
    if (_pickingImages) return;

    final availableSlots = 8 - _existingImages.length - _selectedImages.length;
    if (availableSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Puedes agregar un máximo de 8 fotos.')),
      );
      return;
    }

    setState(() => _pickingImages = true);

    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 80,
        limit: availableSlots,
        requestFullMetadata: false,
      );

      if (images.isEmpty || !mounted) return;

      setState(() {
        _selectedImages.addAll(images.take(availableSlots));
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron seleccionar las imágenes: $error'),
        ),
      );
    } finally {
      if (mounted) setState(() => _pickingImages = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final priceText = _priceController.text.trim().replaceAll(',', '.');

    final price = _priceNegotiable ? 0.0 : double.tryParse(priceText);

    if (price == null || (!_priceNegotiable && price <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un precio válido.')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });
    final marketplaceProvider = context.read<MarketplaceProvider>();
    final newlyUploadedUrls = <String>[];

    try {
      final imageUrls = <String>[];

      // Mantener las imágenes que ya tenía el producto.
      imageUrls.addAll(_existingImages);

      // Agregar las nuevas imágenes seleccionadas.
      for (final image in _selectedImages) {
        final url = await _storageService.uploadProductImage(
          file: image,
          productId: widget.product.id,
          ownerId: widget.product.sellerId,
        );

        imageUrls.add(url);
        newlyUploadedUrls.add(url);
      }

      final updatedProduct = ProductModel(
        id: widget.product.id,
        sellerId: widget.product.sellerId,
        sellerName: widget.product.sellerName,
        sellerEmail: widget.product.sellerEmail,
        sellerPhone: widget.product.sellerPhone,
        sellerPhoto: widget.product.sellerPhoto,
        views: widget.product.views,
        favorites: widget.product.favorites,
        isFeatured: widget.product.isFeatured,
        isSold: widget.product.isSold,
        latitude: widget.product.latitude,
        longitude: widget.product.longitude,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        category: _category,
        listingType: widget.product.listingType,
        priceNegotiable: _priceNegotiable,
        serviceArea: _serviceAreaController.text.trim(),
        availability: _availabilityController.text.trim(),
        condition: _condition,
        country: _countryController.text.trim(),
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        images: imageUrls,
        createdAt: widget.product.createdAt,
        updatedAt: DateTime.now(),
      );

      await marketplaceProvider.updateProduct(updatedProduct);

      // Las fotos retiradas del formulario ya no deben permanecer ocupando
      // espacio en Storage.
      final removedImageUrls = widget.product.images.where(
        (url) => !imageUrls.contains(url),
      );
      await Future.wait(removedImageUrls.map(_storageService.deleteImage));

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      // Si Firestore rechaza la edición, no dejamos fotografías huérfanas.
      await Future.wait(newlyUploadedUrls.map(_storageService.deleteImage));
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
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
        'Editar publicación',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          tooltip: 'Cerrar',
          color: Colors.white,
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
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 280, child: _editPhotoPanel()),
                              const SizedBox(width: 24),
                              Expanded(child: _editFormPanel(wide)),
                            ],
                          )
                        else ...[
                          _editPhotoPanel(),
                          const SizedBox(height: 16),
                          _editFormPanel(wide),
                        ],
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: wide ? 300 : double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFED1C24),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(54),
                              ),
                              onPressed: _saving ? null : _saveChanges,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                _saving ? 'Guardando...' : 'Guardar cambios',
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

  Widget _editPhotoPanel() => _editPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _saving ? null : _pickImages,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 150),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: _buildImageGrid(),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0646D8),
          ),
          onPressed: _saving || _pickingImages ? null : _pickImages,
          icon: _pickingImages
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_photo_alternate_outlined),
          label: Text(
            _pickingImages ? 'Abriendo selector...' : 'Seleccionar imágenes',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_existingImages.length + _selectedImages.length}/8 fotos',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
        ),
      ],
    ),
  );

  Widget _buildImageGrid() {
    final total = _existingImages.length + _selectedImages.length;
    if (total == 0) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_rounded, color: Color(0xFF0646D8), size: 36),
          SizedBox(height: 8),
          Text('Agregar fotos', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Máx. 8 fotos', style: TextStyle(color: Color(0xFF667085))),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var index = 0; index < _existingImages.length; index++)
          _imageTile(
            Image.network(
              _existingImages[index],
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0xFFE4E7EC),
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
            () => setState(() => _existingImages.removeAt(index)),
          ),
        for (var index = 0; index < _selectedImages.length; index++)
          _imageTile(
            XFileImage(file: _selectedImages[index]),
            () => setState(() => _selectedImages.removeAt(index)),
          ),
      ],
    );
  }

  Widget _imageTile(Widget image, VoidCallback onRemove) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(width: 72, height: 72, child: image),
      ),
      Positioned(
        top: 3,
        right: 3,
        child: InkWell(
          onTap: onRemove,
          borderRadius: BorderRadius.circular(20),
          child: const CircleAvatar(
            radius: 11,
            backgroundColor: Colors.white,
            child: Icon(Icons.close, color: Color(0xFFED1C24), size: 15),
          ),
        ),
      ),
    ],
  );

  Widget _editFormPanel(bool wide) => _editPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _editLabel(_isService ? 'Nombre del servicio' : 'Título del producto'),
        TextFormField(
          controller: _titleController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: 'Ej. iPhone 15 Pro'),
          validator: _required,
        ),
        const SizedBox(height: 14),
        if (_isService) ...[
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _priceNegotiable,
            title: const Text('Precio a convenir'),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (value) =>
                setState(() => _priceNegotiable = value ?? false),
          ),
          if (!_priceNegotiable)
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(hintText: 'Ej. 25.000'),
              validator: _required,
            ),
        ] else
          _editPair(
            first: TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(hintText: 'Ej. 650.000'),
              validator: _required,
            ),
            firstLabel: 'Precio',
            second: DropdownButtonFormField<String>(
              initialValue: _condition,
              isExpanded: true,
              decoration: const InputDecoration(),
              items: _conditions
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _condition = value!),
            ),
            secondLabel: 'Condición',
            wide: wide,
          ),
        const SizedBox(height: 14),
        _editLabel(_isService ? 'Especialidad' : 'Categoría'),
        DropdownButtonFormField<String>(
          initialValue: _category,
          isExpanded: true,
          decoration: const InputDecoration(),
          items: _categories
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) => setState(() => _category = value!),
        ),
        const SizedBox(height: 14),
        _editLabel('Descripción'),
        TextFormField(
          controller: _descriptionController,
          minLines: 4,
          maxLines: 7,
          decoration: const InputDecoration(
            hintText: 'Describe tu producto o servicio...',
          ),
          validator: _required,
        ),
        const SizedBox(height: 14),
        _editLabel('Ubicación aproximada'),
        _editPair(
          first: TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(hintText: 'Comuna o ciudad'),
            validator: _required,
          ),
          firstLabel: 'Ciudad',
          second: TextFormField(
            controller: _countryController,
            decoration: const InputDecoration(hintText: 'País'),
            validator: _required,
          ),
          secondLabel: 'País',
          wide: wide,
        ),
        const SizedBox(height: 14),
        if (_isService) ...[
          _editLabel('Zona donde atiende'),
          TextFormField(
            controller: _serviceAreaController,
            validator: _required,
          ),
          const SizedBox(height: 14),
          _editLabel('Disponibilidad'),
          TextFormField(
            controller: _availabilityController,
            validator: _required,
          ),
        ] else ...[
          _editLabel('Dirección (opcional)'),
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

  Widget _editPanel({required Widget child}) => Container(
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

  Widget _editLabel(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
  );

  Widget _editPair({
    required Widget first,
    required String firstLabel,
    required Widget second,
    required String secondLabel,
    required bool wide,
  }) {
    final firstColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_editLabel(firstLabel), first],
    );
    final secondColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_editLabel(secondLabel), second],
    );
    if (!wide) {
      return Column(
        children: [firstColumn, const SizedBox(height: 14), secondColumn],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: firstColumn),
        const SizedBox(width: 16),
        Expanded(child: secondColumn),
      ],
    );
  }
}
