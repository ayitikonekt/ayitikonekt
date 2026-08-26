import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_locale_provider.dart';
import '../../auth/data/user_model.dart';
import '../../auth/services/user_service.dart';

class LocationSettingsPanel extends StatefulWidget {
  final UserModel user;

  const LocationSettingsPanel({super.key, required this.user});

  @override
  State<LocationSettingsPanel> createState() => _LocationSettingsPanelState();
}

class _LocationSettingsPanelState extends State<LocationSettingsPanel> {
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
  static const _languages = [
    'Español',
    'Français',
    'Kreyòl Ayisyen',
    'English',
    'Português',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late String _country;
  late String _language;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.user.city);
    _addressController = TextEditingController(text: widget.user.address);
    _country = _countries.contains(widget.user.country)
        ? widget.user.country
        : 'Chile';
    _language = _languages.contains(widget.user.language)
        ? widget.user.language
        : widget.user.language == 'Kreyòl'
        ? 'Kreyòl Ayisyen'
        : 'Español';
  }

  @override
  void dispose() {
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final localeProvider = context.read<AppLocaleProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);

    try {
      await UserService().updateUser(
        widget.user.copyWith(
          country: _country,
          city: _cityController.text.trim(),
          address: _addressController.text.trim(),
          language: _language,
        ),
      );
      localeProvider.selectLanguageName(_language);
      navigator.pop(true);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la ubicación: $error')),
      );
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
      leading: IconButton(
        tooltip: 'Cerrar',
        onPressed: _saving ? null : () => Navigator.pop(context),
        icon: const Icon(Icons.close_rounded),
      ),
      title: Text(
        context.tr('locationLanguage'),
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4E7EC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF0646D8),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.tr('whereAreYou'),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: _country,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.tr('country'),
                        prefixIcon: const Icon(Icons.public),
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
                          : (value) => setState(() => _country = value!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityController,
                      enabled: !_saving,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: context.tr('cityOrTown'),
                        prefixIcon: const Icon(Icons.location_city_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Ingresa tu comuna o ciudad'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      enabled: !_saving,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: context.tr('addressOptional'),
                        prefixIcon: const Icon(Icons.home_work_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _language,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.tr('language'),
                        prefixIcon: const Icon(Icons.language_rounded),
                      ),
                      items: _languages
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _language = value!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(context.tr(_saving ? 'saving' : 'saveChanges')),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
