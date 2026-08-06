import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class PortfolioFirebaseService {
  static final PortfolioFirebaseService _instance =
      PortfolioFirebaseService._internal();
  factory PortfolioFirebaseService() => _instance;
  PortfolioFirebaseService._internal();

  bool _initialized = false;

  // Sanitize data recursively to ensure type safety
  dynamic _sanitizeValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num) return value;
    if (value is bool) return value;
    if (value is List) {
      return value.map((e) => _sanitizeValue(e)).toList();
    }
    if (value is Map) {
      return _sanitizeData(value);
    }
    return value.toString();
  }

  Map<String, dynamic> _sanitizeData(Map data) {
    final sanitized = <String, dynamic>{};
    for (var entry in data.entries) {
      final key = entry.key?.toString() ?? '';
      sanitized[key] = _sanitizeValue(entry.value);
    }
    return sanitized;
  }

  Future<void> init() async {
    if (_initialized) return;
    try {
      if (Firebase.apps.isNotEmpty) {
        _initialized = true;
        return;
      }
      await Firebase.initializeApp();
      _initialized = true;
    } catch (e) {
      // Ignore "duplicate app" error if it races
      if (e.toString().contains('duplicate')) {
        _initialized = true;
        return;
      }
      debugPrint('[PortfolioFirebaseService] Init failed: $e');
    }
  }

  Future<void> ensureSignedIn() async {
    await init();
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current == null) {
        await FirebaseAuth.instance.signInAnonymously();
        debugPrint('[PortfolioFirebaseService] signed in anonymously');
      }
    } catch (e) {
      debugPrint('[PortfolioFirebaseService] anonymous sign-in failed: $e');
    }
  }

  // Auth methods
  Future<UserCredential> signIn(String email, String password) async {
    await init();
    return FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  User? get currentUser => FirebaseAuth.instance.currentUser;

  // Content management methods
  Future<void> saveContent(String section, Map<String, dynamic> content) async {
    await ensureSignedIn();
    try {
      await FirebaseFirestore.instance
          .collection('portfolio_content')
          .doc(section)
          .set(_sanitizeData(content), SetOptions(merge: true));
      debugPrint(
          '[PortfolioFirebaseService] Saved content for section: $section');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        final msg =
            'Permission denied when saving content for section "$section".\n'
            'Enable anonymous auth or update Firestore security rules to allow this client to write.';
        debugPrint(
            '[PortfolioFirebaseService] Error saving content: ${e.message}');
        throw Exception('$msg (${e.message})');
      }
      debugPrint(
          '[PortfolioFirebaseService] Error saving content: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[PortfolioFirebaseService] Error saving content: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getContent(String section) async {
    await init();
    try {
      final doc = await FirebaseFirestore.instance
          .collection('portfolio_content')
          .doc(section)
          .get();
      return doc.exists ? _sanitizeData(doc.data()!) : null;
    } catch (e) {
      // If Firestore denies permission, avoid noisy stack traces and
      // allow callers to fallback to local assets.
      if (e is FirebaseException && e.code == 'permission-denied') {
        debugPrint(
            '[PortfolioFirebaseService] Firestore permission denied for content "$section"; falling back to local assets.');
        return null;
      }
      debugPrint(
          '[PortfolioFirebaseService] Error getting content: ${e.toString()}');
      return null;
    }
  }

  // Projects management
  Future<void> saveProjects(List<Map<String, dynamic>> projects) async {
    await init();
    try {
      final batch = FirebaseFirestore.instance.batch();
      final projectsRef = FirebaseFirestore.instance.collection('projects');

      // Clear existing
      final existingDocs = await projectsRef.get();
      for (var doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      // Add new with Order
      for (int i = 0; i < projects.length; i++) {
        final project = Map<String, dynamic>.from(projects[i]);
        project['order'] = i; // Save order
        final docRef = projectsRef.doc();
        batch.set(docRef, _sanitizeData(project));
      }

      await batch.commit();
      debugPrint(
          '[PortfolioFirebaseService] Saved ${projects.length} projects');
    } catch (e) {
      debugPrint('[PortfolioFirebaseService] Error saving projects: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getProjects() async {
    await init();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('projects')
          .orderBy('order') // Server-side sort preferred
          .get();

      // Fallback client-side sort if older items don't have 'order'
      final docs =
          snapshot.docs.map((doc) => _sanitizeData(doc.data())).toList();
      docs.sort((a, b) => (int.tryParse(a['order'].toString()) ?? 999)
          .compareTo(int.tryParse(b['order'].toString()) ?? 999));

      return docs;
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') return [];
      debugPrint('[PortfolioFirebaseService] Error getting projects: $e');
      return [];
    }
  }

  // Skills management
  Future<void> saveSkills(List<Map<String, dynamic>> skills) async {
    await init();
    try {
      final batch = FirebaseFirestore.instance.batch();
      final skillsRef = FirebaseFirestore.instance.collection('skills');

      final existingDocs = await skillsRef.get();
      for (var doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      for (int i = 0; i < skills.length; i++) {
        final skill = Map<String, dynamic>.from(skills[i]);
        skill['order'] = i;
        final docRef = skillsRef.doc();
        batch.set(docRef, _sanitizeData(skill));
      }

      await batch.commit();
      debugPrint('[PortfolioFirebaseService] Saved ${skills.length} skills');
    } catch (e) {
      debugPrint('[PortfolioFirebaseService] Error saving skills: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSkills() async {
    await init();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('skills')
          .orderBy('order')
          .get();

      final docs =
          snapshot.docs.map((doc) => _sanitizeData(doc.data())).toList();
      docs.sort((a, b) => (int.tryParse(a['order'].toString()) ?? 999)
          .compareTo(int.tryParse(b['order'].toString()) ?? 999));
      return docs;
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') return [];
      debugPrint('[PortfolioFirebaseService] Error getting skills: $e');
      return [];
    }
  }

  // Certifications management
  Future<void> saveCertifications(
      List<Map<String, dynamic>> certifications) async {
    await init();
    try {
      final batch = FirebaseFirestore.instance.batch();
      final certsRef = FirebaseFirestore.instance.collection('certifications');

      final existingDocs = await certsRef.get();
      for (var doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      for (int i = 0; i < certifications.length; i++) {
        final cert = Map<String, dynamic>.from(certifications[i]);
        cert['order'] = i;
        final docRef = certsRef.doc();
        batch.set(docRef, _sanitizeData(cert));
      }

      await batch.commit();
      debugPrint(
          '[PortfolioFirebaseService] Saved ${certifications.length} certifications');
    } catch (e) {
      debugPrint('[PortfolioFirebaseService] Error saving certifications: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCertifications() async {
    await init();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('certifications')
          .orderBy('order')
          .get();
      final docs =
          snapshot.docs.map((doc) => _sanitizeData(doc.data())).toList();
      docs.sort((a, b) => (int.tryParse(a['order'].toString()) ?? 999)
          .compareTo(int.tryParse(b['order'].toString()) ?? 999));
      return docs;
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') return [];
      debugPrint('[PortfolioFirebaseService] Error getting certifications: $e');
      return [];
    }
  }

  // Volunteer experience management
  Future<void> saveVolunteerExperience(
      List<Map<String, dynamic>> experiences) async {
    await init();
    try {
      final batch = FirebaseFirestore.instance.batch();
      final volunteerRef = FirebaseFirestore.instance.collection('volunteer');

      final existingDocs = await volunteerRef.get();
      for (var doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      for (int i = 0; i < experiences.length; i++) {
        final exp = Map<String, dynamic>.from(experiences[i]);
        exp['order'] = i;
        final docRef = volunteerRef.doc();
        batch.set(docRef, _sanitizeData(exp));
      }

      await batch.commit();
      debugPrint(
          '[PortfolioFirebaseService] Saved ${experiences.length} volunteer experiences');
    } catch (e) {
      debugPrint(
          '[PortfolioFirebaseService] Error saving volunteer experiences: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getVolunteerExperience() async {
    await init();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('volunteer')
          .orderBy('order')
          .get();
      final docs =
          snapshot.docs.map((doc) => _sanitizeData(doc.data())).toList();
      docs.sort((a, b) => (int.tryParse(a['order'].toString()) ?? 999)
          .compareTo(int.tryParse(b['order'].toString()) ?? 999));
      return docs;
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') return [];
      debugPrint(
          '[PortfolioFirebaseService] Error getting volunteer experiences: $e');
      return [];
    }
  }

  // Hackathons management
  Future<void> saveHackathons(List<Map<String, dynamic>> hackathons) async {
    await init();
    try {
      final batch = FirebaseFirestore.instance.batch();
      final hackathonsRef = FirebaseFirestore.instance.collection('hackathons');

      final existingDocs = await hackathonsRef.get();
      for (var doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      for (int i = 0; i < hackathons.length; i++) {
        final hack = Map<String, dynamic>.from(hackathons[i]);
        hack['order'] = i;
        final docRef = hackathonsRef.doc();
        batch.set(docRef, _sanitizeData(hack));
      }

      await batch.commit();
      debugPrint(
          '[PortfolioFirebaseService] Saved ${hackathons.length} hackathons');
    } catch (e) {
      debugPrint('[PortfolioFirebaseService] Error saving hackathons: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getHackathons() async {
    await init();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('hackathons')
          .orderBy('order')
          .get();
      final docs =
          snapshot.docs.map((doc) => _sanitizeData(doc.data())).toList();
      docs.sort((a, b) => (int.tryParse(a['order'].toString()) ?? 999)
          .compareTo(int.tryParse(b['order'].toString()) ?? 999));
      return docs;
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') return [];
      debugPrint('[PortfolioFirebaseService] Error getting hackathons: $e');
      return [];
    }
  }

  // Open Source Contributions management
  Future<void> saveOpenSourceContributions(List<Map<String, dynamic>> contributions) async {
    await init();
    try {
      final batch = FirebaseFirestore.instance.batch();
      final openSourceRef = FirebaseFirestore.instance.collection('open_source');

      final existingDocs = await openSourceRef.get();
      for (var doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      for (int i = 0; i < contributions.length; i++) {
        final contrib = Map<String, dynamic>.from(contributions[i]);
        contrib['order'] = i;
        final docRef = openSourceRef.doc();
        batch.set(docRef, _sanitizeData(contrib));
      }

      await batch.commit();
      debugPrint('[PortfolioFirebaseService] Saved ${contributions.length} open source contributions');
    } catch (e) {
      debugPrint('[PortfolioFirebaseService] Error saving open source contributions: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getOpenSourceContributions() async {
    await init();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('open_source')
          .orderBy('order')
          .get();
      final docs =
          snapshot.docs.map((doc) => _sanitizeData(doc.data())).toList();
      docs.sort((a, b) => (int.tryParse(a['order'].toString()) ?? 999)
          .compareTo(int.tryParse(b['order'].toString()) ?? 999));
      return docs;
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') return [];
      debugPrint('[PortfolioFirebaseService] Error getting open source contributions: $e');
      return [];
    }
  }
}
