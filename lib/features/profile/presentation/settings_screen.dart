import 'package:flutter/material.dart';

import '../../../core/localization/app_locale_provider.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../auth/data/user_model.dart';
import '../../auth/presentation/edit_profile_screen.dart';
import '../../auth/services/user_service.dart';
import '../../home/presentation/location_settings_panel.dart';
import '../../notifications/presentation/notifications_screen.dart';

class SettingsScreen extends StatefulWidget {
  final UserModel user;

  const SettingsScreen({super.key, required this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserModel _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _refreshUser() async {
    final updated = await UserService().getUser(_user.uid);
    if (mounted && updated != null) setState(() => _user = updated);
  }

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    await _refreshUser();
  }

  Future<void> _openLocation() async {
    final width = MediaQuery.sizeOf(context).width;
    bool? changed;
    if (width < 700) {
      changed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FractionallySizedBox(
          heightFactor: .92,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: LocationSettingsPanel(user: _user),
          ),
        ),
      );
    } else {
      changed = await showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
            child: LocationSettingsPanel(user: _user),
          ),
        ),
      );
    }
    if (changed == true) await _refreshUser();
  }

  Future<void> _showInformation(String titleKey, String bodyKey) =>
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        builder: (context) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr(titleKey),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr(bodyKey),
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.tr('accept')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),
    appBar: AppBar(
      leadingWidth: 112,
      leading: const AppBackButton(
        showWhenCannotPop: false,
        foregroundColor: Colors.white,
      ),
      title: Text(context.tr('settings')),
      centerTitle: true,
      backgroundColor: const Color(0xFF0646D8),
      foregroundColor: Colors.white,
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                constraints.maxWidth < 600 ? 14 : 24,
                20,
                constraints.maxWidth < 600 ? 14 : 24,
                36,
              ),
              children: [
                _SectionTitle(context.tr('account')),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: context.tr('editProfile'),
                      subtitle: context.tr('personalInformation'),
                      onTap: _openEditProfile,
                    ),
                    _SettingsTile(
                      icon: Icons.location_on_outlined,
                      title: context.tr('locationLanguage'),
                      subtitle:
                          '${_user.city}, ${_user.country} · ${_user.language}',
                      onTap: _openLocation,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _SectionTitle(context.tr('preferences')),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.notifications_none_rounded,
                      title: context.tr('notifications'),
                      subtitle: context.tr('reviewNotifications'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.palette_outlined,
                      title: context.tr('appearance'),
                      subtitle: context.tr('systemAppearance'),
                      onTap: () => _showInformation(
                        'appearance',
                        'appearanceInformation',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _SectionTitle(context.tr('privacyAndSecurity')),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: context.tr('privacy'),
                      subtitle: context.tr('privacySubtitle'),
                      onTap: () =>
                          _showInformation('privacy', 'privacyInformation'),
                    ),
                    _SettingsTile(
                      icon: Icons.shield_outlined,
                      title: context.tr('security'),
                      subtitle: context.tr('securitySubtitle'),
                      onTap: () =>
                          _showInformation('security', 'securityInformation'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _SectionTitle(context.tr('information')),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.description_outlined,
                      title: context.tr('termsAndPrivacy'),
                      subtitle: context.tr('communityRules'),
                      onTap: () => _showInformation(
                        'termsAndPrivacy',
                        'legalInformation',
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: context.tr('aboutApp'),
                      subtitle: 'AyitiKonekt 1.0.0',
                      onTap: () =>
                          _showInformation('aboutApp', 'aboutInformation'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF667085),
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1) const Divider(height: 1, indent: 64),
        ],
      ],
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    leading: CircleAvatar(
      backgroundColor: const Color(0xFFEAF1FF),
      child: Icon(icon, color: const Color(0xFF0646D8), size: 21),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF98A2B3)),
  );
}
