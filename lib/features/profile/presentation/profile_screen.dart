import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_locale_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/data/user_model.dart';
import '../../auth/services/user_service.dart';
import '../../auth/presentation/edit_profile_screen.dart';
import '../../marketplace/providers/marketplace_provider.dart';
import '../../splash/presentation/country_selection_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../sos/presentation/sos_screen.dart';
import 'my_products_screen.dart';
import '../../marketplace/presentation/favorites_screen.dart';
import '../../reviews/presentation/reviews_screen.dart';
import '../../support/presentation/support_center_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<UserModel?>? _userFuture;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();

    final authUser = context.read<AuthProvider>().user;

    if (authUser != null) {
      _userFuture = UserService().getUser(authUser.uid);
    }
  }

  Future<void> _reloadProfile() async {
    final authUser = context.read<AuthProvider>().user;

    if (authUser == null) return;

    setState(() {
      _userFuture = UserService().getUser(authUser.uid);
    });

    await _userFuture;
  }

  Future<void> _signOut(UserModel user) async {
    if (_signingOut) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    final authProvider = context.read<AuthProvider>();
    final marketplaceProvider = context.read<MarketplaceProvider>();

    setState(() => _signingOut = true);

    try {
      await authProvider.logout();
      marketplaceProvider.setUser(null);

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CountrySelectionScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _signingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cerrar la sesión: $error')),
      );
    }
  }

  void _openProfilePhoto(String photoUrl, String name) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(dialogContext).top + 16,
              right: 16,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(
                  side: BorderSide(color: Colors.white70),
                ),
                child: IconButton(
                  tooltip: context.tr('close'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
              ),
            ),
            if (name.isNotEmpty)
              Positioned(
                left: 24,
                right: 24,
                bottom: 28,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EditProfileScreen(openPhotoPicker: true),
      ),
    );
    if (mounted) await _reloadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.user == null) {
      return Scaffold(
        body: Center(child: Text(context.tr('notAuthenticated'))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: FutureBuilder<UserModel?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar el perfil:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }
          final user = snapshot.data;
          if (user == null) {
            return Center(child: Text(context.tr('profileNotFound')));
          }
          return _buildResponsiveProfile(user);
        },
      ),
    );
  }

  Widget _buildResponsiveProfile(UserModel user) {
    final provider = context.watch<MarketplaceProvider>();
    final publications = provider.allProducts
        .where((product) => product.sellerId == user.uid)
        .toList();
    final sold = publications.where((product) => product.isSold).length;
    final displayName = '${user.name} ${user.lastName}'.trim();

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
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
                      padding: const EdgeInsets.only(bottom: 42),
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
                          child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (Navigator.canPop(context))
                                IconButton(
                                  tooltip: context.tr('back'),
                                  color: Colors.white,
                                  onPressed: () => Navigator.maybePop(context),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                )
                              else
                                const SizedBox(width: 48),
                              const Spacer(),
                              Consumer<MarketplaceProvider>(
                                builder: (context, provider, _) => IconButton(
                                  tooltip: 'Actualizar',
                                  color: Colors.white,
                                  onPressed: provider.loading
                                      ? null
                                      : () async {
                                          await Future.wait([
                                            provider.refresh(),
                                            _reloadProfile(),
                                          ]);
                                        },
                                  icon: provider.loading
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.refresh_rounded),
                                ),
                              ),
                              IconButton(
                                tooltip: context.tr('notifications'),
                                color: Colors.white,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationsScreen(),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.notifications_none_rounded,
                                ),
                              ),
                            ],
                          ),
                          ),
                        ),
                      ),
                    ),
                    Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Semantics(
                            button: true,
                            label: context.tr('profilePhoto'),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: user.photo.isEmpty
                                  ? _openEditProfile
                                  : () => _openProfilePhoto(
                                      user.photo,
                                      displayName,
                                    ),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: constraints.maxWidth < 600 ? 42 : 50,
                                  backgroundColor: const Color(0xFFE4E7EC),
                                  backgroundImage: user.photo.isNotEmpty
                                      ? NetworkImage(user.photo)
                                      : null,
                                  child: user.photo.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 46,
                                          color: Color(0xFF667085),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Tooltip(
                              message: context.tr('editProfile'),
                              child: Material(
                                color: const Color(0xFFF20D1B),
                                shape: const CircleBorder(
                                  side: BorderSide(color: Colors.white, width: 3),
                                ),
                                elevation: 3,
                                child: SizedBox.square(
                                  dimension: 40,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: _openEditProfile,
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 600 ? 14 : 24,
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12101828),
                          blurRadius: 20,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                displayName.isEmpty ? user.email : displayName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (user.verified) ...[
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.verified,
                                color: Color(0xFF1677FF),
                                size: 19,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              user.verified
                                  ? Icons.verified_user_outlined
                                  : Icons.info_outline,
                              size: 15,
                              color: user.verified
                                  ? const Color(0xFF17A673)
                                  : const Color(0xFF667085),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              user.verified
                                  ? context.tr('verifiedMember')
                                  : context.tr('communityMember'),
                              style: TextStyle(
                                color: user.verified
                                    ? const Color(0xFF17A673)
                                    : const Color(0xFF667085),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFB800),
                              size: 20,
                            ),
                            Text(
                              user.reputation.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Color(0xFFFFA000),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.tr('reputation'),
                              style: const TextStyle(color: Color(0xFF667085)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            _stat(
                              '${publications.length}',
                              context.tr('publications'),
                            ),
                            _stat(
                              '${provider.favorites.length}',
                              context.tr('favorites'),
                            ),
                            _stat('$sold', context.tr('sold')),
                          ],
                        ),
                        const Divider(height: 28),
                        _menuItem(
                          Icons.inventory_2_outlined,
                          context.tr('myListings'),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyProductsScreen(),
                            ),
                          ),
                        ),
                        _menuItem(
                          Icons.favorite_border_rounded,
                          context.tr('favorites'),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FavoritesScreen(),
                            ),
                          ),
                        ),
                        _menuItem(
                          Icons.star_border_rounded,
                          context.tr('reviews'),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewsScreen(userId: user.uid),
                            ),
                          ),
                        ),
                        _menuItem(
                          Icons.settings_outlined,
                          context.tr('settings'),
                          () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SettingsScreen(user: user),
                              ),
                            );
                            await _reloadProfile();
                          },
                        ),
                        _menuItem(
                          Icons.warning_amber_rounded,
                          context.tr('sosEmergencies'),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SosScreen(),
                            ),
                          ),
                          color: const Color(0xFFF20D1B),
                        ),
                        _menuItem(
                          Icons.help_outline_rounded,
                          context.tr('helpCenter'),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SupportCenterScreen(
                                userId: user.uid,
                                initialContact: user.email.isNotEmpty
                                    ? user.email
                                    : user.phone,
                              ),
                            ),
                          ),
                        ),
                        _menuItem(
                          Icons.logout_rounded,
                          context.tr(_signingOut ? 'signingOut' : 'signOut'),
                          _signingOut ? null : () => _signOut(user),
                          color: const Color(0xFFF20D1B),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
        ),
      ],
    ),
  );

  Widget _menuItem(
    IconData icon,
    String label,
    VoidCallback? onTap, {
    Color color = const Color(0xFF0646D8),
  }) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: color, size: 22),
    title: Text(
      label,
      style: TextStyle(color: color == const Color(0xFFF20D1B) ? color : null),
    ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      size: 20,
      color: Color(0xFF98A2B3),
    ),
    onTap: onTap,
  );
}
