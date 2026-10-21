import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/content_management_service.dart';
import '../services/portfolio_firebase_service.dart';
import '../services/contact_form_service.dart';

class ComprehensiveAdminPanel extends StatefulWidget {
  const ComprehensiveAdminPanel({super.key});

  @override
  State<ComprehensiveAdminPanel> createState() =>
      _ComprehensiveAdminPanelState();
}

class _ComprehensiveAdminPanelState extends State<ComprehensiveAdminPanel>
    with TickerProviderStateMixin {
  final ContentManagementService _contentService = ContentManagementService();
  final PortfolioFirebaseService _firebaseService = PortfolioFirebaseService();
  final ContactFormService _contactFormService = ContactFormService();

  late TabController _tabController;
  bool _isLoading = false;
  bool _isSaving = false;
  String _statusMessage = '';

  List<Map<String, dynamic>> _formSubmissions = [];
  Map<String, dynamic> _resumeStats = {'total': 0, 'today': 0};

  // Content controllers
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, List<Map<String, dynamic>>> _listData = {};

  // Note: Admin authorization should be enforced server-side via
  // Firebase security rules. Client-side allowlists were removed
  // to avoid unused-field warnings — use server-side checks instead.

  // Helper to safely convert any value to string
  String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    if (value is List) {
      return value
          .map((e) => _safeString(e))
          .where((s) => s.isNotEmpty)
          .join(', ');
    }
    if (value is Map) {
      return value.entries
          .map((e) => '${_safeString(e.key)}: ${_safeString(e.value)}')
          .join(', ');
    }
    return value.toString();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
    _initializeControllers();
    _ensureAuthenticated();
  }

  Future<void> _ensureAuthenticated() async {
    try {
      await _firebaseService.ensureSignedIn();
      if (mounted) {
        setState(() {
          _statusMessage = 'Authenticated successfully';
        });
      }
      await _loadContent();
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Authentication failed: $e';
        });
      }
    }
  }

  void _initializeControllers() {
    // Home section
    _controllers['home_hero'] = TextEditingController();
    _controllers['home_subtitle'] = TextEditingController();
    _controllers['home_description'] = TextEditingController();
    _controllers['home_availability'] = TextEditingController();
    _controllers['home_profile_image'] = TextEditingController();

    // About section
    _controllers['about_title'] = TextEditingController();
    _controllers['about_description'] = TextEditingController();
    _controllers['about_profile_image'] = TextEditingController();

    // Skills section
    _controllers['skills_title'] = TextEditingController();
    _controllers['skills_description'] = TextEditingController();

    // Projects section
    _controllers['projects_title'] = TextEditingController();
    _controllers['projects_description'] = TextEditingController();

    // Open Source section
    _controllers['open_source_title'] = TextEditingController();
    _controllers['open_source_description'] = TextEditingController();

    // Certifications section
    _controllers['certifications_title'] = TextEditingController();
    _controllers['certifications_description'] = TextEditingController();

    // Volunteer section
    _controllers['volunteer_title'] = TextEditingController();
    _controllers['volunteer_description'] = TextEditingController();

    // Contact section
    _controllers['contact_title'] = TextEditingController();
    _controllers['contact_description'] = TextEditingController();
    _controllers['contact_email'] = TextEditingController();
    _controllers['contact_phone'] = TextEditingController();
    _controllers['contact_location'] = TextEditingController();
    _controllers['contact_linkedin'] = TextEditingController();
    _controllers['contact_github'] = TextEditingController();
    _controllers['contact_resume'] = TextEditingController();
    _controllers['contact_schedule_meeting'] = TextEditingController();
    // Additional contact/social fields
    _controllers['contact_social'] = TextEditingController();

    // Community impact (volunteer stats)
    _controllers['community_people'] = TextEditingController();
    _controllers['community_hours'] = TextEditingController();
    _controllers['community_events'] = TextEditingController();

    // Initialize list data
    _listData['experience'] = [];
    _listData['skills'] = [];
    _listData['projects'] = [];
    _listData['open_source'] = [];
    _listData['certifications'] = [];
    _listData['volunteer'] = [];
    _listData['hackathons'] = [];
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading content...';
    });

    try {
      final content = await _contentService.getAllContent();

      // Load home content
      if (content['home'] != null) {
        _controllers['home_hero']!.text = _safeString(content['home']['hero']);
        _controllers['home_subtitle']!.text =
            _safeString(content['home']['subtitle']);
        _controllers['home_description']!.text =
            _safeString(content['home']['description']);
        _controllers['home_availability']!.text =
            _safeString(content['home']['availabilityText'] ?? 'Available for work');
        _controllers['home_profile_image']!.text =
            _safeString(content['home']['profileImage']);
      }

      // Load about content
      if (content['about'] != null) {
        _controllers['about_title']!.text =
            _safeString(content['about']['title']);
        _controllers['about_description']!.text =
            _safeString(content['about']['description']);
        _controllers['about_profile_image']!.text =
            _safeString(content['about']['profileImage']);

        // Robustly load experience list
        final expList = content['about']['experience'];
        if (expList is List) {
          _listData['experience'] = expList.map((item) {
            if (item is Map<String, dynamic>) {
              return item
                  .map((key, value) => MapEntry(key, _safeString(value)));
            }
            return <String, dynamic>{};
          }).toList();
        } else {
          _listData['experience'] = [];
        }
      }

      // Load skills content
      if (content['skills'] != null) {
        _controllers['skills_title']!.text =
            _safeString(content['skills']['title']);
        _controllers['skills_description']!.text =
            _safeString(content['skills']['description']);
      }

      // Load projects content
      if (content['projects'] != null) {
        _controllers['projects_title']!.text =
            _safeString(content['projects']['title']);
        _controllers['projects_description']!.text =
            _safeString(content['projects']['description']);
      }

      // Load open source content
      if (content['open_source'] != null) {
        _controllers['open_source_title']!.text =
            _safeString(content['open_source']['title']);
        _controllers['open_source_description']!.text =
            _safeString(content['open_source']['description']);
      }

      // Load certifications content
      if (content['certifications'] != null) {
        _controllers['certifications_title']!.text =
            _safeString(content['certifications']['title']);
        _controllers['certifications_description']!.text =
            _safeString(content['certifications']['description']);
      }

      // Load volunteer content
      if (content['volunteer'] != null) {
        _controllers['volunteer_title']!.text =
            _safeString(content['volunteer']['title']);
        _controllers['volunteer_description']!.text =
            _safeString(content['volunteer']['description']);
        // Support different shapes: volunteer list may be under 'volunteer' key or directly present
        if (content['volunteer']['volunteer'] is List) {
          _listData['volunteer'] = List<Map<String, dynamic>>.from(
              content['volunteer']['volunteer']);
        } else if (content['volunteer'] is List) {
          _listData['volunteer'] =
              List<Map<String, dynamic>>.from(content['volunteer']);
        }
        // Load community impact metrics if present
        final impact = content['volunteer']['impact'];
        if (impact != null && impact is Map<String, dynamic>) {
          _controllers['community_people']!.text =
              _safeString(impact['people']);
          _controllers['community_hours']!.text = _safeString(impact['hours']);
          _controllers['community_events']!.text =
              _safeString(impact['events']);
        }
      }

      // Load contact content
      if (content['contact'] != null) {
        _controllers['contact_title']!.text =
            _safeString(content['contact']['title']);
        _controllers['contact_description']!.text =
            _safeString(content['contact']['description']);
        _controllers['contact_email']!.text =
            _safeString(content['contact']['email']);
        _controllers['contact_phone']!.text =
            _safeString(content['contact']['phone']);
        _controllers['contact_location']!.text =
            _safeString(content['contact']['location']);
        _controllers['contact_linkedin']!.text =
            _safeString(content['contact']['linkedin']);
        _controllers['contact_github']!.text =
            _safeString(content['contact']['github']);
        _controllers['contact_resume']!.text =
            _safeString(content['contact']['resume']);
        _controllers['contact_schedule_meeting']!.text =
            _safeString(content['contact']['scheduleMeeting']);
        _controllers['contact_social']!.text =
            _safeString(content['contact']['social']);
      }

      // Load list data - ensure lists are initialized even if empty
      try {
        final skillsData = await _firebaseService.getSkills();
        _listData['skills'] = skillsData.map((e) {
          try {
            final m = Map<String, dynamic>.from(e);
            // Sanitize all values to prevent type errors
            final sanitized = <String, dynamic>{};
            m.forEach((key, value) {
              if (value is String ||
                  value is num ||
                  value is bool ||
                  value == null) {
                sanitized[key] = value;
              } else if (value is List) {
                sanitized[key] = value;
              } else {
                sanitized[key] = _safeString(value);
              }
            });
            return sanitized;
          } catch (err) {
            debugPrint('Error sanitizing skill item: $err');
            return <String, dynamic>{};
          }
        }).toList();
      } catch (e) {
        _listData['skills'] = [];
        debugPrint('Error loading skills: $e');
      }

      try {
        final projectsData = await _firebaseService.getProjects();
        _listData['projects'] = projectsData.map((e) {
          try {
            final m = Map<String, dynamic>.from(e);
            // Sanitize all values to prevent type errors
            final sanitized = <String, dynamic>{};
            m.forEach((key, value) {
              if (value is String ||
                  value is num ||
                  value is bool ||
                  value == null) {
                sanitized[key] = value;
              } else if (value is List) {
                sanitized[key] = value;
              } else {
                sanitized[key] = _safeString(value);
              }
            });
            return sanitized;
          } catch (err) {
            debugPrint('Error sanitizing project item: $err');
            return <String, dynamic>{};
          }
        }).toList();
      } catch (e) {
        _listData['projects'] = [];
        debugPrint('Error loading projects: $e');
      }

      try {
        final openSourceData = await _firebaseService.getOpenSourceContributions();
        _listData['open_source'] = openSourceData.map((e) {
          try {
            final m = Map<String, dynamic>.from(e);
            final sanitized = <String, dynamic>{};
            m.forEach((key, value) {
              if (value is String ||
                  value is num ||
                  value is bool ||
                  value == null) {
                sanitized[key] = value;
              } else if (value is List) {
                sanitized[key] = value;
              } else {
                sanitized[key] = _safeString(value);
              }
            });
            return sanitized;
          } catch (err) {
            debugPrint('Error sanitizing open source item: $err');
            return <String, dynamic>{};
          }
        }).toList();
      } catch (e) {
        _listData['open_source'] = [];
        debugPrint('Error loading open source: $e');
      }

      try {
        final certsData = await _firebaseService.getCertifications();
        _listData['certifications'] = certsData.map((e) {
          try {
            final m = Map<String, dynamic>.from(e);
            // normalize older 'image' key to 'imageUrl'
            if (m.containsKey('image') && !m.containsKey('imageUrl')) {
              m['imageUrl'] = m['image'];
              m.remove('image');
            }
            // ensure verified boolean
            if (m.containsKey('verified')) {
              final v = m['verified'];
              if (v is String) m['verified'] = v.toLowerCase() == 'true';
            } else {
              m['verified'] = false;
            }
            // Sanitize all values to prevent type errors
            final sanitized = <String, dynamic>{};
            m.forEach((key, value) {
              if (value is String ||
                  value is num ||
                  value is bool ||
                  value == null) {
                sanitized[key] = value;
              } else if (value is List) {
                sanitized[key] = value;
              } else {
                sanitized[key] = _safeString(value);
              }
            });
            return sanitized;
          } catch (err) {
            debugPrint('Error sanitizing certification item: $err');
            return <String, dynamic>{};
          }
        }).toList();
      } catch (e) {
        _listData['certifications'] = [];
        debugPrint('Error loading certifications: $e');
      }

      try {
        _listData['volunteer'] =
            (await _firebaseService.getVolunteerExperience())
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
      } catch (e) {
        _listData['volunteer'] = [];
        debugPrint('Error loading volunteer: $e');
      }

      // Load hackathons
      try {
        _listData['hackathons'] = (await _firebaseService.getHackathons())
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } catch (e) {
        _listData['hackathons'] = [];
        debugPrint('Error loading hackathons: $e');
      }

      // Load form submissions and resume stats
      _formSubmissions = await _contactFormService.getContactSubmissions();
      _resumeStats = await _contactFormService.getResumeDownloadStats();

      setState(() {
        _statusMessage = 'Content loaded successfully';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error loading content: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveContent() async {
    setState(() {
      _isSaving = true;
      _statusMessage = 'Saving content...';
    });

    // Ensure user is authenticated (anonymous or email/password)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Try to sign in anonymously
      try {
        await _firebaseService.ensureSignedIn();
      } catch (e) {
        setState(() {
          _statusMessage = 'Authentication required. Error: $e';
          _isSaving = false;
        });
        return;
      }
    }

    try {
      final content = {
        'home': {
          'hero': _controllers['home_hero']!.text,
          'subtitle': _controllers['home_subtitle']!.text,
          'description': _controllers['home_description']!.text,
          'availabilityText': _controllers['home_availability']!.text,
          'profileImage': _controllers['home_profile_image']!.text,
        },
        'about': {
          'title': _controllers['about_title']!.text,
          'description': _controllers['about_description']!.text,
          'profileImage': _controllers['about_profile_image']!.text,
          'experience': _listData['experience'],
        },
        'skills': {
          'title': _controllers['skills_title']!.text,
          'description': _controllers['skills_description']!.text,
          'skills': _listData['skills'],
        },
        'projects': {
          'title': _controllers['projects_title']!.text,
          'description': _controllers['projects_description']!.text,
          'projects': _listData['projects'],
        },
        'open_source': {
          'title': _controllers['open_source_title']!.text,
          'description': _controllers['open_source_description']!.text,
          'contributions': _listData['open_source'],
        },
        'certifications': {
          'title': _controllers['certifications_title']!.text,
          'description': _controllers['certifications_description']!.text,
          'certifications': _listData['certifications'],
        },
        'volunteer': {
          'title': _controllers['volunteer_title']!.text,
          'description': _controllers['volunteer_description']!.text,
          'volunteer': _listData['volunteer'],
          'impact': {
            'people': _controllers['community_people']!.text,
            'hours': _controllers['community_hours']!.text,
            'events': _controllers['community_events']!.text,
          },
        },
        'contact': {
          'title': _controllers['contact_title']!.text,
          'description': _controllers['contact_description']!.text,
          'email': _controllers['contact_email']!.text,
          'phone': _controllers['contact_phone']!.text,
          'location': _controllers['contact_location']!.text,
          'linkedin': _controllers['contact_linkedin']!.text,
          'github': _controllers['contact_github']!.text,
          'resume': _controllers['contact_resume']!.text,
          'scheduleMeeting': _controllers['contact_schedule_meeting']!.text,
          'social': _controllers['contact_social']!.text,
        },
      };

      await _contentService.saveAllContent(content);

      // Save list items to Firestore collections
      await _firebaseService.saveSkills(_listData['skills'] ?? []);
      await _firebaseService.saveProjects(_listData['projects'] ?? []);
      await _firebaseService
          .saveOpenSourceContributions(_listData['open_source'] ?? []);
      await _firebaseService
          .saveCertifications(_listData['certifications'] ?? []);
      await _firebaseService
          .saveVolunteerExperience(_listData['volunteer'] ?? []);
      await _firebaseService.saveHackathons(_listData['hackathons'] ?? []);

      if (mounted) {
        setState(() {
          _statusMessage = 'Content saved successfully!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error saving content: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Firebase Data'),
          content: const Text(
            'This will permanently delete ALL portfolio content from Firebase:\n\n'
            '• Skills\n'
            '• Projects\n'
            '• Certifications\n'
            '• Volunteer Experience\n'
            '• Hackathons\n\n'
            'This action cannot be undone. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearAllFirebaseData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllFirebaseData() async {
    setState(() {
      _isSaving = true;
      _statusMessage = 'Deleting all Firebase data...';
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Delete all documents from each collection
      final collections = [
        'skills',
        'projects',
        'certifications',
        'volunteer',
        'hackathons'
      ];

      for (final collectionName in collections) {
        final snapshot = await firestore.collection(collectionName).get();
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }

      if (mounted) {
        setState(() {
          _statusMessage =
              'All Firebase data deleted successfully! You can now add fresh content.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error deleting Firebase data: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Website',
          onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Portfolio Admin Panel',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage your portfolio content',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryBackground,
        foregroundColor: AppTheme.textColor,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBackground,
                AppTheme.secondaryBackground.withOpacity(0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.borderColor.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.accentBlue,
          indicatorWeight: 3,
          labelColor: AppTheme.accentBlue,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13,
          ),
          tabs: const [
            Tab(
                text: 'Home',
                icon: Icon(Icons.home, size: 20),
                key: Key('tab_home')),
            Tab(
                text: 'About',
                icon: Icon(Icons.person, size: 20),
                key: Key('tab_about')),
            Tab(
                text: 'Skills',
                icon: Icon(Icons.code, size: 20),
                key: Key('tab_skills')),
            Tab(
                text: 'Projects',
                icon: Icon(Icons.work, size: 20),
                key: Key('tab_projects')),
            Tab(
                text: 'Open Source',
                icon: Icon(Icons.code_off, size: 20),
                key: Key('tab_open_source')),
            Tab(
                text: 'Certifications',
                icon: Icon(Icons.school, size: 20),
                key: Key('tab_certifications')),
            Tab(
                text: 'Volunteer',
                icon: Icon(Icons.volunteer_activism, size: 20),
                key: Key('tab_volunteer')),
            Tab(
                text: 'Hackathons',
                icon: Icon(Icons.emoji_events, size: 20),
                key: Key('tab_hackathons')),
            Tab(
                text: 'Contact',
                icon: Icon(Icons.email, size: 20),
                key: Key('tab_contact')),
            Tab(
                text: 'Form Submissions',
                icon: Icon(Icons.inbox, size: 20),
                key: Key('tab_forms')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded),
            tooltip: 'View Portfolio Site',
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear All Firebase Data',
            onPressed: _showClearDataDialog,
          ),
          IconButton(
            key: const Key('btn_refresh'),
            onPressed: _loadContent,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload Content',
          ),
          // Show current signed-in admin email (if available)
          Builder(builder: (ctx) {
            final user = FirebaseAuth.instance.currentUser;
            final email = user?.email ?? '';
            if (email.isNotEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_rounded, size: 14, color: AppTheme.accentCyan),
                    const SizedBox(width: 6),
                    Text(
                      email,
                      style: const TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.cardColor,
                  title: const Text('Sign Out', style: TextStyle(color: AppTheme.textColor)),
                  content: const Text(
                    'Are you sure you want to sign out of the admin panel?',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await FirebaseAuth.instance.signOut();
              }
            },
          ),
          const SizedBox(width: 4),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentBlue,
                  AppTheme.accentCyan,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentBlue.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveContent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              key: const Key('btn_save_all'),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_upload_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Save All',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Status message
          if (_statusMessage.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _statusMessage.contains('Error')
                      ? [
                          AppTheme.errorColor.withOpacity(0.2),
                          AppTheme.errorColor.withOpacity(0.1),
                        ]
                      : [
                          AppTheme.successColor.withOpacity(0.2),
                          AppTheme.successColor.withOpacity(0.1),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_statusMessage.contains('Error')
                          ? AppTheme.errorColor
                          : AppTheme.successColor)
                      .withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _statusMessage.contains('Error')
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    color: _statusMessage.contains('Error')
                        ? AppTheme.errorColor
                        : AppTheme.successColor,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _statusMessage.contains('Error')
                            ? AppTheme.errorColor
                            : AppTheme.successColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppTheme.textSecondary,
                    onPressed: () => setState(() => _statusMessage = ''),
                    tooltip: 'Dismiss',
                  ),
                ],
              ),
            ),

          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHomeTab(),
                      _buildAboutTab(),
                      _buildSkillsTab(),
                      _buildProjectsTab(),
                      _buildOpenSourceTab(),
                      _buildCertificationsTab(),
                      _buildVolunteerTab(),
                      _buildHackathonsTab(),
                      _buildContactTab(),
                      _buildFormSubmissionsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return _buildSectionContent([
      _buildTextField('Hero Text', _controllers['home_hero']!,
          key: 'home_hero'),
      _buildTextField('Subtitle', _controllers['home_subtitle']!,
          key: 'home_subtitle'),
      _buildTextField('Description', _controllers['home_description']!,
          maxLines: 3, key: 'home_description'),
      _buildTextField('Availability Tag Text', _controllers['home_availability']!,
          key: 'home_availability'),
      _buildTextField('Profile Image URL', _controllers['home_profile_image']!,
          key: 'home_profile_image'),
    ]);
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Section',
            style: AppTheme.sectionTitleStyle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 24),
          _buildTextField('Title', _controllers['about_title']!,
              key: 'about_title'),
          const SizedBox(height: 16),
          _buildTextField('Description', _controllers['about_description']!,
              maxLines: 5, key: 'about_description'),
          const SizedBox(height: 16),
          _buildTextField(
              'Profile Image URL', _controllers['about_profile_image']!,
              helperText:
                  'Use direct image URLs (e.g., avatars.githubusercontent.com)',
              key: 'about_profile_image'),
          const SizedBox(height: 32),
          Divider(color: AppTheme.borderColor),
          const SizedBox(height: 16),
          _buildListManager(
              'Experience', _listData['experience']!, _addExperienceItem,
              keyPrefix: 'experience'),
        ],
      ),
    );
  }

  Widget _buildSkillsTab() {
    final skillsList = _listData['skills'] ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentCyan.withOpacity(0.15),
                  AppTheme.accentCyan.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.accentCyan.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.code,
                        color: AppTheme.accentCyan,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Skills Section',
                      style: AppTheme.sectionTitleStyle.copyWith(fontSize: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTextField('Section Title', _controllers['skills_title']!,
                    key: 'skills_title'),
                const SizedBox(height: 16),
                _buildTextField(
                    'Section Description', _controllers['skills_description']!,
                    maxLines: 3, key: 'skills_description'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildListManager('Skills', skillsList, _addSkillItem,
              keyPrefix: 'skills'),
        ],
      ),
    );
  }

  Widget _buildOpenSourceTab() {
    final openSourceList = _listData['open_source'] ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentBlue.withOpacity(0.15),
                  AppTheme.accentBlue.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.accentBlue.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.code,
                        color: AppTheme.accentBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Open Source Contributions Section',
                      style: AppTheme.sectionTitleStyle.copyWith(fontSize: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTextField(
                    'Section Title', _controllers['open_source_title']!,
                    key: 'open_source_title'),
                const SizedBox(height: 16),
                _buildTextField('Section Description',
                    _controllers['open_source_description']!,
                    maxLines: 3, key: 'open_source_description'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildListManager('Open Source', openSourceList, _addOpenSourceItem,
              keyPrefix: 'open_source'),
        ],
      ),
    );
  }

  Widget _buildProjectsTab() {
    final projectsList = _listData['projects'] ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentPink.withOpacity(0.15),
                  AppTheme.accentPink.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.accentPink.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPink.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.work,
                        color: AppTheme.accentPink,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Projects Section',
                      style: AppTheme.sectionTitleStyle.copyWith(fontSize: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTextField(
                    'Section Title', _controllers['projects_title']!,
                    key: 'projects_title'),
                const SizedBox(height: 16),
                _buildTextField('Section Description',
                    _controllers['projects_description']!,
                    maxLines: 3, key: 'projects_description'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildListManager('Projects', projectsList, _addProjectItem,
              keyPrefix: 'projects'),
        ],
      ),
    );
  }

  Widget _buildCertificationsTab() {
    final certificationsList = _listData['certifications'] ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentPurple.withOpacity(0.15),
                  AppTheme.accentPurple.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.accentPurple.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: AppTheme.accentPurple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Certifications Section',
                      style: AppTheme.sectionTitleStyle.copyWith(fontSize: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTextField(
                    'Section Title', _controllers['certifications_title']!,
                    key: 'certifications_title'),
                const SizedBox(height: 16),
                _buildTextField('Section Description',
                    _controllers['certifications_description']!,
                    maxLines: 3, key: 'certifications_description'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildListManager(
              'Certifications', certificationsList, _addCertificationItem,
              keyPrefix: 'certifications'),
        ],
      ),
    );
  }

  Widget _buildVolunteerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Volunteer Section',
            style: AppTheme.sectionTitleStyle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 24),
          _buildTextField('Section Title', _controllers['volunteer_title']!,
              key: 'volunteer_title'),
          const SizedBox(height: 16),
          _buildTextField(
              'Section Description', _controllers['volunteer_description']!,
              maxLines: 3, key: 'volunteer_description'),
          const SizedBox(height: 32),
          Divider(color: AppTheme.borderColor),
          const SizedBox(height: 16),
          _buildListManager('Volunteer Experience', _listData['volunteer']!,
              _addVolunteerItem,
              keyPrefix: 'volunteer'),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return _buildSectionContent([
      _buildTextField('Title', _controllers['contact_title']!,
          key: 'contact_title'),
      _buildTextField('Description', _controllers['contact_description']!,
          maxLines: 3, key: 'contact_description'),
      _buildTextField('Email', _controllers['contact_email']!,
          key: 'contact_email'),
      _buildTextField('Phone', _controllers['contact_phone']!,
          key: 'contact_phone'),
      _buildTextField('Location', _controllers['contact_location']!,
          key: 'contact_location'),
      _buildTextField('LinkedIn URL', _controllers['contact_linkedin']!,
          key: 'contact_linkedin'),
      _buildTextField('GitHub URL', _controllers['contact_github']!,
          key: 'contact_github'),
      _buildTextField('Resume URL', _controllers['contact_resume']!,
          key: 'contact_resume'),
    ]);
  }

  Widget _buildHackathonsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hackathons & Events',
            style: AppTheme.sectionTitleStyle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 24),
          _buildListManager(
              'Hackathons', _listData['hackathons']!, _addHackathonItem,
              keyPrefix: 'hackathons'),
        ],
      ),
    );
  }

  Widget _buildFormSubmissionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contact Form Submissions',
                style: AppTheme.sectionTitleStyle.copyWith(fontSize: 20),
              ),
              ElevatedButton.icon(
                onPressed: _loadContent,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Resume Download Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resume Downloads',
                  style: AppTheme.cardTitleStyle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Downloads',
                        _resumeStats['total'].toString(),
                        Icons.download,
                        AppTheme.accentBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Today',
                        _resumeStats['today'].toString(),
                        Icons.today,
                        AppTheme.accentCyan,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Divider(color: AppTheme.borderColor),
          const SizedBox(height: 16),
          // Form Submissions
          if (_formSubmissions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text(
                  'No form submissions yet',
                  style: AppTheme.bodyTextStyle.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            )
          else
            ..._formSubmissions.asMap().entries.map((entry) {
              final index = entry.key;
              final submission = entry.value;
              return _buildFormSubmissionCard(submission, index);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.bodyTextStyle.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.cardTitleStyle.copyWith(
              fontSize: 28,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSubmissionCard(Map<String, dynamic> submission, int index) {
    final isRead = submission['read'] ?? false;
    final isReplied = submission['replied'] ?? false;
    final timestamp = submission['timestamp'];
    String timeStr = 'Unknown time';

    if (timestamp != null) {
      try {
        final dt = (timestamp as Timestamp).toDate();
        timeStr =
            '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        timeStr = 'Invalid date';
      }
    }

    return Container(
      key: Key('form_submission_$index'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isRead ? AppTheme.cardColor : AppTheme.cardColorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead
              ? AppTheme.borderColor
              : AppTheme.accentBlue.withOpacity(0.3),
          width: isRead ? 1 : 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submission['name'] ?? 'Unknown',
                      style: AppTheme.cardTitleStyle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      submission['email'] ?? '',
                      style: AppTheme.bodyTextStyle.copyWith(
                        fontSize: 14,
                        color: AppTheme.accentBlue,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (!isRead)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'NEW',
                        style: TextStyle(
                          color: AppTheme.accentBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (isReplied)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'REPLIED',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Subject: ${submission['subject'] ?? 'No subject'}',
            style: AppTheme.bodyTextStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            submission['message'] ?? '',
            style: AppTheme.bodyTextStyle.copyWith(
              color: AppTheme.textSecondary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            timeStr,
            style: AppTheme.bodyTextStyle.copyWith(
              fontSize: 12,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isRead)
                TextButton.icon(
                  onPressed: () async {
                    await _contactFormService.markAsRead(submission['id']);
                    await _loadContent();
                  },
                  icon: const Icon(Icons.mark_email_read, size: 18),
                  label: const Text('Mark as Read'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accentBlue,
                  ),
                ),
              if (!isReplied)
                TextButton.icon(
                  onPressed: () async {
                    await _contactFormService.markAsReplied(submission['id']);
                    await _loadContent();
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Mark as Replied'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.successColor,
                  ),
                ),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Delete Submission'),
                      content: const Text(
                          'Are you sure you want to delete this submission?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _contactFormService
                        .deleteSubmission(submission['id']);
                    await _loadContent();
                  }
                },
                icon: const Icon(Icons.delete, color: AppTheme.errorColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, String? helperText, String? key}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextField(
        key: key != null ? Key('field_$key') : null,
        controller: controller,
        maxLines: maxLines,
        style: AppTheme.bodyTextStyle.copyWith(
          color: AppTheme.textColor,
        ),
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          helperMaxLines: 2,
          filled: true,
          fillColor: Colors.transparent,
          labelStyle: TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          helperStyle: TextStyle(
            color: AppTheme.textGray,
            fontSize: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.accentBlue,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildListManager(
      String title, List<Map<String, dynamic>> items, Function() onAdd,
      {required String keyPrefix}) {
    // Get color based on prefix
    Color accentColor = AppTheme.accentBlue;
    if (keyPrefix == 'skills') {
      accentColor = AppTheme.accentCyan;
    } else if (keyPrefix == 'certifications') {
      accentColor = AppTheme.accentPurple;
    } else if (keyPrefix == 'projects') {
      accentColor = AppTheme.accentPink;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withOpacity(0.15),
                accentColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.cardTitleStyle.copyWith(
                      fontSize: 24,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                    style: AppTheme.bodyTextStyle.copyWith(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  key: Key('btn_add_$keyPrefix'),
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text(
                    'Add Item',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: AppTheme.glassDecoration(),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No items yet',
                    style: AppTheme.bodyTextStyle.copyWith(
                      fontSize: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click "Add Item" to create your first entry',
                    style: AppTheme.bodyTextStyle.copyWith(
                      fontSize: 14,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final movedItem = items.removeAt(oldIndex);
                items.insert(newIndex, movedItem);
              });
            },
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                key: ValueKey('reorderable_${keyPrefix}_${item.hashCode}_$index'),
                child: _buildListItem(title, item, index, keyPrefix, items),
              );
            },
          ),
      ],
    );
  }

  Widget _buildListItem(
      String title, Map<String, dynamic> item, int index, String keyPrefix, List<Map<String, dynamic>> itemsList) {
    // Get display name based on item type - safely convert to string
    final displayName =
        _safeString(item['title'] ?? item['name'] ?? item['repoName'] ?? 'Untitled');

    // Safely get subtitle from various possible fields
    String subtitle = '';
    if (item['description'] != null) {
      subtitle = _safeString(item['description']);
    } else if (item['category'] != null) {
      subtitle = _safeString(item['category']);
    } else if (item['issuer'] != null) {
      subtitle = _safeString(item['issuer']);
    } else if (item['organization'] != null) {
      subtitle = _safeString(item['organization']);
    }

    // Get color based on item type
    Color itemColor = AppTheme.accentBlue;
    if (keyPrefix == 'skills') {
      itemColor = AppTheme.accentCyan;
    } else if (keyPrefix == 'certifications') {
      itemColor = AppTheme.accentPurple;
    } else if (keyPrefix == 'projects') {
      itemColor = AppTheme.accentPink;
    }

    return Container(
      key: Key('item_${keyPrefix}_$index'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            itemColor.withOpacity(0.1),
            itemColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: itemColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: itemColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Drag handle icon for reordering
          ReorderableDragStartListener(
            index: index,
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Icon(
                  Icons.drag_indicator,
                  color: itemColor.withOpacity(0.7),
                  size: 24,
                ),
              ),
            ),
          ),
          // Item number badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: itemColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: itemColor.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: itemColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTheme.cardTitleStyle.copyWith(
                    fontSize: 18,
                    color: AppTheme.textColor,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: AppTheme.bodyTextStyle.copyWith(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Additional info badges
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (item['proficiency'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Proficiency: ${_safeString(item['proficiency'])}%',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (item['verified'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: AppTheme.successColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: AppTheme.successColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (item['category'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: itemColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _safeString(item['category']),
                          style: TextStyle(
                            color: itemColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Action buttons (Up, Down, Edit, Delete)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  key: Key('btn_move_up_${keyPrefix}_$index'),
                  onPressed: index > 0
                      ? () {
                          setState(() {
                            final moved = itemsList.removeAt(index);
                            itemsList.insert(index - 1, moved);
                          });
                        }
                      : null,
                  icon: Icon(Icons.arrow_upward,
                      color: index > 0 ? itemColor : AppTheme.textGray.withOpacity(0.3)),
                  tooltip: 'Move Up',
                ),
              ),
              const SizedBox(width: 6),
              Container(
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  key: Key('btn_move_down_${keyPrefix}_$index'),
                  onPressed: index < itemsList.length - 1
                      ? () {
                          setState(() {
                            final moved = itemsList.removeAt(index);
                            itemsList.insert(index + 1, moved);
                          });
                        }
                      : null,
                  icon: Icon(Icons.arrow_downward,
                      color: index < itemsList.length - 1 ? itemColor : AppTheme.textGray.withOpacity(0.3)),
                  tooltip: 'Move Down',
                ),
              ),
              const SizedBox(width: 6),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  key: Key('btn_edit_${keyPrefix}_$index'),
                  onPressed: () => _editListItem(title, item, index),
                  icon: const Icon(Icons.edit, color: AppTheme.accentBlue),
                  tooltip: 'Edit',
                ),
              ),
              const SizedBox(width: 6),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  key: Key('btn_delete_${keyPrefix}_$index'),
                  onPressed: () => _deleteListItem(title, index),
                  icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                  tooltip: 'Delete',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addExperienceItem() {
    _showItemDialog('Add Experience', {
      'title': '',
      'company': '',
      'description': '',
      'startDate': '',
      'endDate': '',
      'current': false,
    }, (item) {
      setState(() {
        _listData['experience']!.add(item);
      });
    });
  }

  void _addSkillItem() {
    _showItemDialog('Add Skill', {
      'name': '',
      'category': '',
      'proficiency': 0,
      'imageUrl': '',
    }, (item) {
      setState(() {
        _listData['skills']!.add(item);
      });
    });
  }

  void _addProjectItem() {
    _showItemDialog('Add Project', {
      'title': '',
      'description': '',
      'pullQuote': '',
      'type': 'web', // mobile, web, desktop
      'tech': [],
      'github': '',
      'demo': '',
      'image': '',
    }, (item) {
      setState(() {
        _listData['projects']!.add(item);
      });
    });
  }

  void _addOpenSourceItem() {
    _showItemDialog('Add Open Source Contribution', {
      'repoName': '',
      'description': '',
      'prLink': '',
      'tags': [],
      'mergedPrCount': '',
    }, (item) {
      setState(() {
        _listData['open_source']!.add(item);
      });
    });
  }

  void _addCertificationItem() {
    _showItemDialog('Add Certification', {
      'title': '',
      'issuer': '',
      'date': '',
      'credentialId': '',
      'verificationUrl': '',
      'imageUrl': '',
      'verified': false,
      'category': '',
    }, (item) {
      setState(() {
        _listData['certifications']!.add(item);
      });
    });
  }

  void _addVolunteerItem() {
    _showItemDialog('Add Volunteer Experience', {
      'title': '',
      'organization': '',
      'description': '',
      'startDate': '',
      'endDate': '',
      'current': false,
    }, (item) {
      setState(() {
        _listData['volunteer']!.add(item);
      });
    });
  }

  void _addHackathonItem() {
    _showItemDialog('Add Hackathon', {
      'title': '',
      'event': '',
      'description': '',
      'date': '',
      'achievement': '',
      'link': '',
    }, (item) {
      setState(() {
        _listData['hackathons']!.add(item);
      });
    });
  }

  void _editListItem(String title, Map<String, dynamic> item, int index) {
    _showItemDialog('Edit ${title.substring(0, title.length - 1)}', item,
        (updatedItem) {
      setState(() {
        if (title == 'Experience') {
          _listData['experience']![index] = updatedItem;
        } else if (title == 'Skills') {
          _listData['skills']![index] = updatedItem;
        } else if (title == 'Projects') {
          _listData['projects']![index] = updatedItem;
        } else if (title == 'Open Source') {
          _listData['open_source']![index] = updatedItem;
        } else if (title == 'Certifications') {
          _listData['certifications']![index] = updatedItem;
        } else if (title == 'Volunteer Experience') {
          _listData['volunteer']![index] = updatedItem;
        } else if (title == 'Hackathons') {
          _listData['hackathons']![index] = updatedItem;
        }
      });
    });
  }

  void _deleteListItem(String title, int index) {
    setState(() {
      if (title == 'Experience') {
        _listData['experience']!.removeAt(index);
      } else if (title == 'Skills') {
        _listData['skills']!.removeAt(index);
      } else if (title == 'Projects') {
        _listData['projects']!.removeAt(index);
      } else if (title == 'Open Source') {
        _listData['open_source']!.removeAt(index);
      } else if (title == 'Certifications') {
        _listData['certifications']!.removeAt(index);
      } else if (title == 'Volunteer Experience') {
        _listData['volunteer']!.removeAt(index);
      } else if (title == 'Hackathons') {
        _listData['hackathons']!.removeAt(index);
      }
    });
  }

  String? _getFieldHelper(String key) {
    switch (key.toLowerCase()) {
      case 'tech':
        return 'Enter technologies separated by commas (e.g., Flutter, Dart, Firebase)';
      case 'tags':
        return 'Enter tags as a JSON array (e.g., ["Dart", "Flutter", "Bug Fix"])';
      case 'prlink':
        return 'Enter the direct URL to the merged PRs search/list';
      case 'mergedprcount':
        return 'Optional number of merged PRs (e.g. 3)';
      case 'imageurl':
      case 'image':
        return 'Direct image URL (e.g., https://example.com/image.png)';
      case 'proficiency':
        return 'Skill level from 0-100';
      case 'verified':
        return 'Enter true or false';
      case 'current':
        return 'Enter true if currently ongoing, false otherwise';
      default:
        return null;
    }
  }

  void _showItemDialog(String title, Map<String, dynamic> item,
      Function(Map<String, dynamic>) onSave) {
    final controllers = <String, TextEditingController>{};
    final originalTypes = <String, Type>{};

    // Initialize controllers with current values and remember types
    item.forEach((key, value) {
      originalTypes[key] = value.runtimeType;
      if (value is List) {
        // join list items for an editable representation
        controllers[key] = TextEditingController(text: jsonEncode(value));
      } else if (value is Map) {
        controllers[key] = TextEditingController(text: jsonEncode(value));
      } else {
        controllers[key] = TextEditingController(text: value?.toString() ?? '');
      }
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppTheme.borderColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentBlue.withOpacity(0.2),
                      AppTheme.accentPurple.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: AppTheme.accentBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTheme.cardTitleStyle.copyWith(fontSize: 22),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Form fields
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: item.keys.map((key) {
                      final isMultiline =
                          key.toLowerCase().contains('description') ||
                              key.toLowerCase().contains('tech');
                      final maxLines = isMultiline ? 3 : 1;

                      String label =
                          key.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim();
                      label = label[0].toUpperCase() + label.substring(1);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBackground.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.borderColor.withOpacity(0.3),
                            ),
                          ),
                          child: TextField(
                            key: Key('dialog_field_$key'),
                            controller: controllers[key],
                            decoration: InputDecoration(
                              labelText: label,
                              helperText: _getFieldHelper(key),
                              helperMaxLines: 2,
                              filled: true,
                              fillColor: Colors.transparent,
                              labelStyle: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              helperStyle: TextStyle(
                                color: AppTheme.textGray,
                                fontSize: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppTheme.accentBlue,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            maxLines: maxLines,
                            style: AppTheme.bodyTextStyle.copyWith(
                              color: AppTheme.textColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key('dialog_cancel'),
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.accentBlue, AppTheme.accentCyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      key: const Key('dialog_save'),
                      onPressed: () {
                        final updatedItem = <String, dynamic>{};

                        controllers.forEach((key, controller) {
                          final text = controller.text.trim();
                          final Type? t = originalTypes[key];

                          dynamic parsed;
                          try {
                            if (t == int) {
                              parsed = int.tryParse(text) ?? 0;
                            } else if (t == double) {
                              parsed = double.tryParse(text) ?? 0.0;
                            } else if (t == bool) {
                              parsed =
                                  (text.toLowerCase() == 'true' || text == '1');
                            } else if (t == List) {
                              // try JSON array first, otherwise comma-separated
                              if (text.startsWith('[')) {
                                parsed =
                                    (jsonDecode(text) as List).cast<dynamic>();
                              } else if (text.isEmpty) {
                                parsed = <dynamic>[];
                              } else {
                                parsed = text
                                    .split(',')
                                    .map((s) => s.trim())
                                    .where((s) => s.isNotEmpty)
                                    .toList();
                              }
                            } else if (t == Map) {
                              if (text.startsWith('{')) {
                                parsed =
                                    jsonDecode(text) as Map<String, dynamic>;
                              } else {
                                parsed = text;
                              }
                            } else {
                              // original type unknown (new fields): try to infer
                              if (text.startsWith('[') || text.contains(',')) {
                                try {
                                  parsed = jsonDecode(text);
                                } catch (_) {
                                  parsed = text
                                      .split(',')
                                      .map((s) => s.trim())
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                }
                              } else if (int.tryParse(text) != null) {
                                parsed = int.tryParse(text);
                              } else if (double.tryParse(text) != null) {
                                parsed = double.tryParse(text);
                              } else if (text.toLowerCase() == 'true' ||
                                  text.toLowerCase() == 'false') {
                                parsed = text.toLowerCase() == 'true';
                              } else {
                                parsed = text;
                              }
                            }
                          } catch (e) {
                            // fallback to raw text
                            parsed = text;
                          }

                          updatedItem[key] = parsed;
                        });

                        onSave(updatedItem);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Save',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
