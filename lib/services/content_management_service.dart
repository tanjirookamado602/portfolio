import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'portfolio_firebase_service.dart';

class ContentManagementService {
  static final ContentManagementService _instance =
      ContentManagementService._internal();
  factory ContentManagementService() => _instance;
  ContentManagementService._internal();

  final PortfolioFirebaseService _firebaseService = PortfolioFirebaseService();

  // Home section content
  Future<void> saveHomeContent({
    required String hero,
    required String subtitle,
    required String description,
    String? profileImage,
    String? availabilityText,
    bool? availableForWork,
  }) async {
    await _firebaseService.saveContent('home', {
      'hero': hero,
      'subtitle': subtitle,
      'description': description,
      'profileImage': profileImage,
      'availabilityText': availabilityText,
      'availableForWork': availableForWork,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getHomeContent() async {
    return await _firebaseService.getContent('home');
  }

  // About section content
  Future<void> saveAboutContent({
    required String title,
    required String description,
    required List<Map<String, dynamic>> experience,
    String? profileImage,
    List<Map<String, dynamic>>? stats,
    List<String>? techStack,
  }) async {
    await _firebaseService.saveContent('about', {
      'title': title,
      'description': description,
      'experience': experience,
      'profileImage': profileImage,
      if (stats != null) 'stats': stats,
      if (techStack != null) 'techStack': techStack,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getAboutContent() async {
    return await _firebaseService.getContent('about');
  }

  // Skills content
  Future<void> saveSkillsContent({
    required String title,
    required String description,
    required List<Map<String, dynamic>> skills,
  }) async {
    await _firebaseService.saveContent('skills', {
      'title': title,
      'description': description,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
    await _firebaseService.saveSkills(skills);
  }

  Future<Map<String, dynamic>?> getSkillsContent() async {
    return await _firebaseService.getContent('skills');
  }

  // Projects content
  Future<void> saveProjectsContent({
    required String title,
    required String description,
    required List<Map<String, dynamic>> projects,
  }) async {
    await _firebaseService.saveContent('projects', {
      'title': title,
      'description': description,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
    await _firebaseService.saveProjects(projects);
  }

  Future<Map<String, dynamic>?> getProjectsContent() async {
    return await _firebaseService.getContent('projects');
  }

  // Certifications content
  Future<void> saveCertificationsContent({
    required String title,
    required String description,
    required List<Map<String, dynamic>> certifications,
  }) async {
    await _firebaseService.saveContent('certifications', {
      'title': title,
      'description': description,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
    await _firebaseService.saveCertifications(certifications);
  }

  Future<Map<String, dynamic>?> getCertificationsContent() async {
    return await _firebaseService.getContent('certifications');
  }

  // Open Source content
  Future<void> saveOpenSourceContent({
    required String title,
    required String description,
    required List<Map<String, dynamic>> contributions,
  }) async {
    await _firebaseService.saveContent('open_source', {
      'title': title,
      'description': description,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
    await _firebaseService.saveOpenSourceContributions(contributions);
  }

  Future<Map<String, dynamic>?> getOpenSourceContent() async {
    return await _firebaseService.getContent('open_source');
  }

  // Volunteer content
  Future<void> saveVolunteerContent({
    required String title,
    required String description,
    required List<Map<String, dynamic>> volunteer,
    Map<String, dynamic>? impact,
  }) async {
    await _firebaseService.saveContent('volunteer', {
      'title': title,
      'description': description,
      if (impact != null) 'impact': impact,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
    await _firebaseService.saveVolunteerExperience(volunteer);
  }

  Future<Map<String, dynamic>?> getVolunteerContent() async {
    return await _firebaseService.getContent('volunteer');
  }

  // Contact content
  Future<void> saveContactContent({
    required String title,
    required String description,
    required String email,
    required String phone,
    required String location,
    required String linkedin,
    required String github,
    required String resume,
    String? scheduleMeeting,
    String? social,
  }) async {
    await _firebaseService.saveContent('contact', {
      'title': title,
      'description': description,
      'email': email,
      'phone': phone,
      'location': location,
      'linkedin': linkedin,
      'github': github,
      'resume': resume,
      'scheduleMeeting': scheduleMeeting,
      'social': social,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getContactContent() async {
    return await _firebaseService.getContent('contact');
  }

  // Get all content for admin panel
  Future<Map<String, dynamic>> getAllContent() async {
    try {
      final home = await getHomeContent();
      final about = await getAboutContent();
      final skills = await getSkillsContent();
      final projects = await getProjectsContent();
      final certifications = await getCertificationsContent();
      final volunteer = await getVolunteerContent();
      final contact = await getContactContent();
      final openSource = await getOpenSourceContent();

      // Fallback to local assets if Firestore data is null
      final Map<String, dynamic> result = {
        'home': home ?? await _loadLocalAsset('home'),
        'about': about ?? await _loadLocalAsset('about'),
        'skills': skills ?? await _loadLocalAsset('skills'),
        'projects': projects ?? await _loadLocalAsset('projects'),
        'open_source': openSource ?? {'title': 'Open Source Contributions', 'description': 'Merged pull requests and contributions to public repositories'},
        'certifications':
            certifications ?? await _loadLocalAsset('certifications'),
        'volunteer': volunteer ?? await _loadLocalAsset('volunteer'),
        'contact': contact ?? await _loadLocalAsset('contact'),
      };

      return result;
    } catch (e) {
      debugPrint('[ContentManagementService] Error getting all content: $e');
      return {};
    }
  }

  // Helper method to load local asset
  Future<Map<String, dynamic>?> _loadLocalAsset(String section) async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/$section.json');
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint(
          '[ContentManagementService] Error loading local asset $section: $e');
      return null;
    }
  }

  // Save all content from admin panel
  Future<void> saveAllContent(Map<String, dynamic> content) async {
    try {
      if (content['home'] != null) {
        await saveHomeContent(
          hero: content['home']['hero'] ?? '',
          subtitle: content['home']['subtitle'] ?? '',
          description: content['home']['description'] ?? '',
          profileImage: content['home']['profileImage'],
          availabilityText: content['home']['availabilityText'],
          availableForWork: content['home']['availableForWork'] is bool
              ? content['home']['availableForWork']
              : null,
        );
      }

      if (content['about'] != null) {
        await saveAboutContent(
          title: content['about']['title'] ?? '',
          description: content['about']['description'] ?? '',
          experience: List<Map<String, dynamic>>.from(
              content['about']['experience'] ?? []),
          profileImage: content['about']['profileImage'],
          stats: content['about']['stats'] is List
              ? List<Map<String, dynamic>>.from(content['about']['stats'])
              : null,
          techStack: content['about']['techStack'] is List
              ? List<String>.from(content['about']['techStack'])
              : null,
        );
      }

      if (content['skills'] != null) {
        await saveSkillsContent(
          title: content['skills']['title'] ?? '',
          description: content['skills']['description'] ?? '',
          skills: List<Map<String, dynamic>>.from(
              content['skills']['skills'] ?? []),
        );
      }

      if (content['projects'] != null) {
        await saveProjectsContent(
          title: content['projects']['title'] ?? '',
          description: content['projects']['description'] ?? '',
          projects: List<Map<String, dynamic>>.from(
              content['projects']['projects'] ?? []),
        );
      }

      if (content['open_source'] != null) {
        await saveOpenSourceContent(
          title: content['open_source']['title'] ?? '',
          description: content['open_source']['description'] ?? '',
          contributions: List<Map<String, dynamic>>.from(
              content['open_source']['contributions'] ?? []),
        );
      }

      if (content['certifications'] != null) {
        await saveCertificationsContent(
          title: content['certifications']['title'] ?? '',
          description: content['certifications']['description'] ?? '',
          certifications: List<Map<String, dynamic>>.from(
              content['certifications']['certifications'] ?? []),
        );
      }

      if (content['volunteer'] != null) {
        await saveVolunteerContent(
          title: content['volunteer']['title'] ?? '',
          description: content['volunteer']['description'] ?? '',
          volunteer: List<Map<String, dynamic>>.from(
              content['volunteer']['volunteer'] ?? []),
          impact: content['volunteer']['impact'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(content['volunteer']['impact'])
              : null,
        );
      }

      if (content['contact'] != null) {
        await saveContactContent(
          title: content['contact']['title'] ?? '',
          description: content['contact']['description'] ?? '',
          email: content['contact']['email'] ?? '',
          phone: content['contact']['phone'] ?? '',
          location: content['contact']['location'] ?? '',
          linkedin: content['contact']['linkedin'] ?? '',
          github: content['contact']['github'] ?? '',
          resume: content['contact']['resume'] ?? '',
          scheduleMeeting: content['contact']['scheduleMeeting'],
          social: content['contact']['social'],
        );
      }

      debugPrint('[ContentManagementService] All content saved successfully');
    } catch (e) {
      debugPrint('[ContentManagementService] Error saving all content: $e');
      rethrow;
    }
  }
}
