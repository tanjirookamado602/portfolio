import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ResponsiveNavbar extends StatefulWidget {
  final Map<String, GlobalKey> sectionKeys;
  final Function(String) onSectionTap;
  final String? activeSection;

  const ResponsiveNavbar({
    super.key,
    required this.sectionKeys,
    required this.onSectionTap,
    this.activeSection,
  });

  @override
  State<ResponsiveNavbar> createState() => _ResponsiveNavbarState();
}

class _ResponsiveNavbarState extends State<ResponsiveNavbar>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isMenuOpen = false;
  String? _activeSection;

  final List<Map<String, dynamic>> _navItems = [
    {'label': 'Home', 'key': 'home', 'icon': Icons.home},
    {'label': 'About', 'key': 'about', 'icon': Icons.person},
    {'label': 'Skills', 'key': 'skills', 'icon': Icons.code},
    {'label': 'Open Source', 'key': 'open_source', 'icon': Icons.source},
    {'label': 'Projects', 'key': 'projects', 'icon': Icons.work},
    {'label': 'Certifications', 'key': 'certifications', 'icon': Icons.school},
    {'label': 'Hackathons', 'key': 'hackathons', 'icon': Icons.emoji_events},
    {
      'label': 'Volunteer',
      'key': 'volunteer',
      'icon': Icons.volunteer_activism
    },
    {'label': 'Contact', 'key': 'contact', 'icon': Icons.email},
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _onNavItemTap(String key) {
    setState(() {
      _activeSection = key;
      _isMenuOpen = false;
    });
    widget.onSectionTap(key);
  }

  String get _currentActiveSection => widget.activeSection ?? _activeSection ?? 'home';

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1100;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.responsivePadding(context),
            vertical: 16,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.bgPrimary,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.borderSubtle,
                width: 1,
              ),
            ),
          ),
          child: isDesktop ? _buildDesktopNav() : _buildMobileNav(),
        ),
      ),
    );
  }

  Widget _buildDesktopNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildLogo(),
        _buildNavItems(),
        _buildAdminButton(),
      ],
    );
  }

  Widget _buildMobileNav() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLogo(),
            Row(
              children: [
                _buildAdminButton(),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _toggleMenu,
                  icon: Icon(
                    _isMenuOpen ? Icons.close : Icons.menu,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (_isMenuOpen) _buildMobileMenu(),
      ],
    );
  }

  Widget _buildLogo() {
    final width = MediaQuery.of(context).size.width;
    final fontSize = width < 400 ? 16.0 : (width < 600 ? 18.0 : 22.0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _onNavItemTap('home'),
        child: Text(
          'Muhammad Assad Ullah',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: fontSize,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildNavItems() {
    return Row(
      children: _navItems.map((item) {
        final isActive = _currentActiveSection == item['key'];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _NavItemHover(
            label: item['label'],
            isActive: isActive,
            onTap: () => _onNavItemTap(item['key']),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileMenu() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border.all(color: AppTheme.borderSubtle),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: _navItems.map((item) {
          final isActive = _currentActiveSection == item['key'];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _buildMobileNavItem(
              label: item['label'],
              icon: item['icon'],
              isActive: isActive,
              onTap: () => _onNavItemTap(item['key']),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileNavItem({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.bgSurfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? AppTheme.accentPrimary : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? AppTheme.accentPrimary : AppTheme.textMuted,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTheme.bodyTextStyle.copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? AppTheme.textPrimary : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminButton() {
    return TextButton(
      onPressed: () {
        print('Admin button pressed');
        Navigator.of(context).pushNamed('/admin');
      },
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.textFaint,
        textStyle: AppTheme.labelMeta.copyWith(fontSize: 12),
      ),
      child: const Text('Admin'),
    );
  }
}

class _NavItemHover extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItemHover({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItemHover> createState() => _NavItemHoverState();
}

class _NavItemHoverState extends State<_NavItemHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: AppTheme.bodyTextStyle.copyWith(
                  color: (widget.isActive || _isHovered)
                      ? AppTheme.textPrimary
                      : AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 2,
                width: (widget.isActive || _isHovered) ? 30 : 0,
                color: AppTheme.accentPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
