import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../core/localization/app_locale_provider.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/auth_provider.dart';
import '../data/user_model.dart';
import '../services/user_service.dart';
import '../../marketplace/services/storage_service.dart';
import '../../../shared/widgets/xfile_image.dart';

class EditProfileScreen extends StatefulWidget {
  final bool openPhotoPicker;

  const EditProfileScreen({super.key, this.openPhotoPicker = false});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _countries = [
    'Chile',
    'Haití',
    'República Dominicana',
    'México',
    'Estados Unidos',
    'Canadá',
    'Francia',
    'Brasil',
  ];
  final _formKey = GlobalKey<FormState>();

  XFile? _selectedImage;
  String? _currentPhotoUrl;

  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _lastNameController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _cityController = TextEditingController();

  String _country = 'Chile';
  String _language = 'Español';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    if (widget.openPhotoPicker) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pickImageFromGallery();
      });
    }
  }

  Future<void> _loadProfile() async {
    final authUser = context.read<AuthProvider>().user;

    if (authUser == null) {
      return;
    }

    try {
      final user = await UserService().getUser(authUser.uid);

      if (user == null || !mounted) {
        return;
      }

      setState(() {
        _nameController.text = user.name;
        _lastNameController.text = user.lastName;
        _phoneController.text = user.phone;
        _cityController.text = user.city;
        _currentPhotoUrl = user.photo;

        if (_countries.contains(user.country)) {
          _country = user.country;
        }

        if (user.language == 'Español' ||
            user.language == 'Français' ||
            user.language == 'English' ||
            user.language == 'Português' ||
            user.language == 'Kreyòl Ayisyen') {
          _language = user.language;
        } else if (user.language == 'Kreyòl') {
          _language = 'Kreyòl Ayisyen';
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar el perfil: $e')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null || !mounted) return;

      setState(() {
        _selectedImage = image;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo seleccionar la foto: $error')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authUser = context.read<AuthProvider>().user;
    final localeProvider = context.read<AppLocaleProvider>();

    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay un usuario autenticado')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final userService = UserService();
      final storageService = StorageService();

      final existingUser = await userService.getUser(authUser.uid);

      String? photoUrl = existingUser?.photo;

      if (_selectedImage != null) {
        photoUrl = await storageService.uploadProfileImage(
          file: _selectedImage!,
          uid: authUser.uid,
        );
      }

      if (existingUser == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el perfil del usuario')),
        );
        return;
      }

      final updatedUser = UserModel(
        uid: existingUser.uid,
        email: existingUser.email,
        name: _nameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        country: _country,
        city: _cityController.text.trim(),
        address: existingUser.address,
        language: _language,
        photo: photoUrl ?? existingUser.photo,
        verified: existingUser.verified,
        reputation: existingUser.reputation,
        createdAt: existingUser.createdAt,
      );

      await userService.updateUser(updatedUser);

      if (!mounted) return;

      localeProvider.selectLanguageName(_language);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar el perfil: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),
    body: SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 44),
                        child: Container(
                          height: constraints.maxWidth < 600 ? 145 : 170,
                          decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFF0646D8),
                              Color(0xFF0D47A1),
                              Color(0xFFF20D1B),
                            ],
                            stops: [0, .62, 1],
                          ),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(22),
                          ),
                        ),
                          child: SafeArea(
                            bottom: false,
                            child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(width: 4),
                              const AppBackButton(
                                showWhenCannotPop: false,
                                foregroundColor: Colors.white,
                              ),
                              const Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 17),
                                  child: Text(
                                    'Editar perfil',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Cerrar',
                                color: Colors.white,
                                onPressed: () => Navigator.maybePop(context),
                                icon: const Icon(Icons.close_rounded),
                              ),
                              const SizedBox(width: 4),
                            ],
                            ),
                          ),
                        ),
                      ),
                      Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: SizedBox.square(
                                  dimension: constraints.maxWidth < 600
                                      ? 88
                                      : 104,
                                  child: _selectedImage != null
                                      ? XFileImage(file: _selectedImage!)
                                      : _currentPhotoUrl?.isNotEmpty == true
                                      ? Image.network(
                                          _currentPhotoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              const _EmptyProfilePhoto(),
                                        )
                                      : const _EmptyProfilePhoto(),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Material(
                                color: const Color(0xFF0646D8),
                                shape: const CircleBorder(),
                                child: IconButton(
                                  tooltip: 'Cambiar foto',
                                  color: Colors.white,
                                  onPressed: _saving
                                      ? null
                                      : _pickImageFromGallery,
                                  icon: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      constraints.maxWidth < 600 ? 14 : 24,
                      0,
                      constraints.maxWidth < 600 ? 14 : 24,
                      30,
                    ),
                    child: Container(
                      padding: EdgeInsets.all(
                        constraints.maxWidth < 420 ? 16 : 22,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE4E7EC)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x10101828),
                            blurRadius: 20,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Información personal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _editProfilePair(
                              constraints.maxWidth >= 600,
                              _profileField(
                                controller: _nameController,
                                label: 'Nombre',
                                icon: Icons.person_outline,
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Ingresa tu nombre'
                                    : null,
                              ),
                              _profileField(
                                controller: _lastNameController,
                                label: 'Apellido',
                                icon: Icons.badge_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _editProfilePair(
                              constraints.maxWidth >= 600,
                              _profileField(
                                controller: _phoneController,
                                label: 'Teléfono',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                              _profileField(
                                controller: _cityController,
                                label: 'Comuna o ciudad',
                                icon: Icons.location_city_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _editProfilePair(
                              constraints.maxWidth >= 600,
                              DropdownButtonFormField<String>(
                                initialValue: _country,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'País',
                                  prefixIcon: Icon(Icons.public),
                                ),
                                items: _countries
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(value),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _saving
                                    ? null
                                    : (value) =>
                                          setState(() => _country = value!),
                              ),
                              DropdownButtonFormField<String>(
                                initialValue: _language,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Idioma',
                                  prefixIcon: Icon(Icons.language),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Español',
                                    child: Text('Español'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Français',
                                    child: Text('Français'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Kreyòl Ayisyen',
                                    child: Text('Kreyòl Ayisyen'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'English',
                                    child: Text('English'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Português',
                                    child: Text('Português'),
                                  ),
                                ],
                                onChanged: _saving
                                    ? null
                                    : (value) =>
                                          setState(() => _language = value!),
                              ),
                            ),
                            const SizedBox(height: 26),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF20D1B),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _saving ? null : _saveProfile,
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
                          ],
                        ),
                      ),
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

  Widget _profileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    validator: validator,
    enabled: !_saving,
  );

  Widget _editProfilePair(bool wide, Widget first, Widget second) {
    if (!wide) {
      return Column(children: [first, const SizedBox(height: 16), second]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 16),
        Expanded(child: second),
      ],
    );
  }
}

class _EmptyProfilePhoto extends StatelessWidget {
  const _EmptyProfilePhoto();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFE4E7EC),
    child: Center(
      child: Icon(Icons.person, size: 50, color: Color(0xFF667085)),
    ),
  );
}
