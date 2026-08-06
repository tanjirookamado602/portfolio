// ignore_for_file: use_build_context_synchronously, prefer_const_constructors
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_config.dart';
import 'screens/home_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/about_screen.dart';
import 'screens/skills_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/hackathons_screen.dart';
import 'screens/certifications_screen.dart';
import 'screens/volunteer_screen.dart';
import 'screens/open_source_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/error_screen.dart';
import 'admin/admin_gate.dart';
import 'widgets/responsive_navbar.dart';
import 'widgets/error_boundary.dart';
import 'widgets/animated_background.dart';
import 'utils/url_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: firebaseOptions);
  } catch (_) {}

  runApp(const PortfolioApp());
}

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Muhammad Assad Ullah',
      theme: AppTheme.darkTheme,
      initialRoute: '/splash',
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const ErrorScreen(),
        );
      },
      routes: {
        '/splash': (c) => const SplashScreen(),
        '/': (c) => const _Root(),
        '/projects': (c) => const ProjectsScreen(),
        '/about': (c) => const AboutScreen(),
        '/skills': (c) => const SkillsScreen(),
        '/contact': (c) => const ContactScreen(),
        '/hackathons': (c) => const HackathonsScreen(),
        '/certifications': (c) => const CertificationsScreen(),
        '/volunteer': (c) => const VolunteerScreen(),
        '/open_source': (c) => const OpenSourceScreen(),
        '/admin': (c) => const AdminGate(),
        '/error': (c) => const ErrorScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {
    'home': GlobalKey(),
    'about': GlobalKey(),
    'skills': GlobalKey(),
    'open_source': GlobalKey(),
    'projects': GlobalKey(),
    'certifications': GlobalKey(),
    'hackathons': GlobalKey(),
    'volunteer': GlobalKey(),
    'contact': GlobalKey(),
  };

  void _scrollTo(String section) {
    final key = _sectionKeys[section];
    if (key == null) return;
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('[Portfolio] Platform animations disabled (Reduce Motion): ${MediaQuery.of(context).disableAnimations}');
    return Scaffold(
      body: AnimatedBackground(
        child: Column(
          children: [
            ResponsiveNavbar(
              sectionKeys: _sectionKeys,
              onSectionTap: _scrollTo,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    Container(
                      key: _sectionKeys['home'],
                      child: ErrorBoundary(
                        sectionName: 'Home',
                        child: HomeScreen(
                          onViewWorkPressed: () => _scrollTo('projects'),
                          onContactPressed: () => _scrollTo('contact'),
                        ),
                      ),
                    ),
                    Container(
                      key: _sectionKeys['about'],
                      child: const ErrorBoundary(
                        sectionName: 'About',
                        child: AboutScreen(),
                      ),
                    ),
                    Container(
                      key: _sectionKeys['skills'],
                      child: const ErrorBoundary(
                        sectionName: 'Skills',
                        child: SkillsScreen(),
                      ),
                    ),
                    Container(
                      key: _sectionKeys['open_source'],
                      child: const ErrorBoundary(
                        sectionName: 'Open Source',
                        child: OpenSourceScreen(),
                      ),
                    ),
                    Container(
                      key: _sectionKeys['projects'],
                      child: ErrorBoundary(
                        sectionName: 'Projects',
                        child: ProjectsScreen(compact: true),
                      ),
                    ),
                    Container(
                      key: _sectionKeys['certifications'],
                      child: const ErrorBoundary(
                        sectionName: 'Certifications',
                        child: CertificationsScreen(),
                      ),
                    ),
                    Container(
                      key: _sectionKeys['hackathons'],
                      child: const ErrorBoundary(
                        sectionName: 'Hackathons',
                        child: HackathonsScreen(),
                      ),
                    ),
                    Container(
                      key: _sectionKeys['volunteer'],
                      child: const ErrorBoundary(
                        sectionName: 'Volunteer',
                        child: VolunteerScreen(),
                      ),
                    ),
                    Container(
                      key: _sectionKeys['contact'],
                      child: const ErrorBoundary(
                        sectionName: 'Contact',
                        child: ContactScreen(),
                      ),
                    ),
                    const SizedBox(height: 60),
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.bgPrimary,
        border: Border(
          top: BorderSide(color: AppTheme.borderSubtle, width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.responsivePadding(context),
        vertical: 40,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '© ${DateTime.now().year} Muhammad Assad Ullah.',
            style: AppTheme.labelMeta,
          ),
          Row(
            children: [
              _FooterHoverLink(
                  label: 'GitHub', url: 'https://github.com/AsadullahAJ'),
              const SizedBox(width: 24),
              _FooterHoverLink(
                  label: 'LinkedIn',
                  url: 'https://linkedin.com/in/muhammad-assad-ullah'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterHoverLink extends StatefulWidget {
  final String label;
  final String url;

  const _FooterHoverLink({required this.label, required this.url});

  @override
  State<_FooterHoverLink> createState() => _FooterHoverLinkState();
}

class _FooterHoverLinkState extends State<_FooterHoverLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => UrlUtils.launch(widget.url),
        child: Text(
          widget.label,
          style: AppTheme.labelMeta.copyWith(
            color: _isHovered ? AppTheme.accentPrimary : AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
