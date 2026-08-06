import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/project_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _initialized = false;

  /// Initialize Firebase.
  ///
  /// On web, you can optionally pass [options] (FirebaseOptions) to initialize
  /// programmatically instead of relying on `web/index.html` insertion.
  Future<void> init({FirebaseOptions? options}) async {
    if (_initialized) return;
    if (kIsWeb) {
      // For web we prefer explicit options to avoid depending on web/index.html.
      if (options != null) {
        await Firebase.initializeApp(options: options);
      } else {
        // Fallback to default behavior which will read from index.html if present.
        await Firebase.initializeApp();
      }
    } else {
      // Native platforms (Android/iOS/macOS) pick up options from native build files.
      await Firebase.initializeApp();
    }

    debugPrint('[FirebaseService] initialized (web=$kIsWeb)');

    // Attempt silent anonymous sign-in so that clients which require an
    // authenticated user (Firestore rules that allow only authenticated
    // writes) can succeed without forcing manual login. If anonymous auth
    // is not enabled in the Firebase project this will fail harmlessly.
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current == null) {
        await FirebaseAuth.instance.signInAnonymously();
        debugPrint('[FirebaseService] signed in anonymously');
      }
    } catch (e) {
      debugPrint('[FirebaseService] anonymous sign-in failed: $e');
      // Don't rethrow; caller code will handle permission errors explicitly
      // when performing write operations.
    }

    _initialized = true;
  }

  // Auth
  Future<UserCredential> signIn(String email, String password) async {
    await init();
    return FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  /// Returns the currently signed in [User], or null if not signed in.
  /// Ensure [init] has been called before accessing this getter.
  User? get currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      // If Firebase isn't initialized yet on web, accessing FirebaseAuth.instance
      // may throw. Return null so callers can continue (they should call init()).
      return null;
    }
  }

  // Firestore metadata operations: store project metadata only
  CollectionReference<Map<String, dynamic>> get _projectsRef =>
      FirebaseFirestore.instance.collection('projects');

  Future<void> pushProjects(List<Project> projects) async {
    await init();
    // Diagnostic: show current user and attempt writes
    final user = FirebaseAuth.instance.currentUser;
    // ignore: avoid_print
    print(
        '[FirebaseService] pushProjects called by user=${user?.uid} email=${user?.email}');
    try {
      final batch = FirebaseFirestore.instance.batch();
      final localIds = <String>{};
      for (final p in projects) {
        final doc = _projectsRef.doc(p.id);
        batch.set(doc, p.toJson());
        localIds.add(p.id);
      }
      await batch.commit();

      // Now compute remote docs that are not present locally and delete them
      final remoteSnap = await _projectsRef.get();
      final remoteIds = remoteSnap.docs.map((d) => d.id).toSet();
      final toDelete = remoteIds.difference(localIds);
      if (toDelete.isNotEmpty) {
        final delBatch = FirebaseFirestore.instance.batch();
        for (final id in toDelete) {
          delBatch.delete(_projectsRef.doc(id));
        }
        await delBatch.commit();
        debugPrint(
            '[FirebaseService] deleted ${toDelete.length} remote docs not present locally');
      }
      debugPrint(
          '[FirebaseService] pushProjects committed ${projects.length} documents');
    } on FirebaseException catch (e) {
      // Provide a clearer hint for permission issues
      if (e.code == 'permission-denied') {
        final msg = 'Permission denied when writing to Firestore.\n'
            'Possible fixes: enable anonymous auth or adjust Firestore rules to allow this client.';
        debugPrint(
            '[FirebaseService] pushProjects permission-denied: ${e.message}');
        throw Exception('$msg (${e.message})');
      }
      debugPrint('[FirebaseService] pushProjects failed: ${e.message}');
      rethrow;
    } catch (e, st) {
      print('[FirebaseService] pushProjects failed: $e\n$st');
      rethrow;
    }
  }

  /// Delete a single project by id from Firestore.
  Future<void> deleteProject(String id) async {
    await init();
    try {
      await _projectsRef.doc(id).delete();
      debugPrint('[FirebaseService] deleteProject $id succeeded');
    } catch (e, st) {
      // ignore: avoid_print
      print('[FirebaseService] deleteProject failed: $e\n$st');
      rethrow;
    }
  }

  Future<List<Project>> fetchProjects() async {
    await init();
    final snap = await _projectsRef.get();
    return snap.docs
        .map((d) => Project.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  // Generic collection helpers for raw JSON-like content (used by admin for other sections)
  CollectionReference<Map<String, dynamic>> _collectionRef(String name) =>
      FirebaseFirestore.instance.collection(name);

  /// Push a map of id -> data to [collectionName], then delete remote docs not present in [localIds].
  Future<void> pushCollectionRaw(
      String collectionName, Map<String, Map<String, dynamic>> data) async {
    await init();
    final batch = FirebaseFirestore.instance.batch();
    final localIds = data.keys.toSet();
    final ref = _collectionRef(collectionName);
    for (final entry in data.entries) {
      batch.set(ref.doc(entry.key), entry.value);
    }
    try {
      await batch.commit();

      // delete remote docs not present locally
      final remoteSnap = await ref.get();
      final remoteIds = remoteSnap.docs.map((d) => d.id).toSet();
      final toDelete = remoteIds.difference(localIds);
      if (toDelete.isNotEmpty) {
        final delBatch = FirebaseFirestore.instance.batch();
        for (final id in toDelete) {
          delBatch.delete(ref.doc(id));
        }
        await delBatch.commit();
        debugPrint(
            '[FirebaseService] pushCollectionRaw deleted ${toDelete.length} remote docs in $collectionName');
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        final msg =
            'Permission denied when writing to Firestore collection "${collectionName}".\n'
            'Enable anonymous auth or adjust Firestore security rules to allow this client to write.';
        debugPrint(
            '[FirebaseService] pushCollectionRaw permission-denied: ${e.message}');
        throw Exception('$msg (${e.message})');
      }
      rethrow;
    }
  }

  Future<void> deleteDoc(String collectionName, String id) async {
    await init();
    await _collectionRef(collectionName).doc(id).delete();
  }

  Future<Map<String, Map<String, dynamic>>> fetchCollectionRaw(
      String collectionName) async {
    await init();
    final snap = await _collectionRef(collectionName).get();
    final out = <String, Map<String, dynamic>>{};
    for (final d in snap.docs) {
      out[d.id] = d.data();
    }
    return out;
  }
}
