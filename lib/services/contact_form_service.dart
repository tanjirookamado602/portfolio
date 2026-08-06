import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ContactFormService {
  static final ContactFormService _instance = ContactFormService._internal();
  factory ContactFormService() => _instance;
  ContactFormService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit a contact form
  Future<void> submitContactForm({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      await _firestore.collection('contact_submissions').add({
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'replied': false,
      });
      debugPrint('[ContactFormService] Form submitted successfully');
    } catch (e) {
      debugPrint('[ContactFormService] Error submitting form: $e');
      rethrow;
    }
  }

  // Get all contact form submissions
  Future<List<Map<String, dynamic>>> getContactSubmissions() async {
    try {
      final snapshot = await _firestore
          .collection('contact_submissions')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[ContactFormService] Error fetching submissions: $e');
      return [];
    }
  }

  // Mark submission as read
  Future<void> markAsRead(String submissionId) async {
    try {
      await _firestore
          .collection('contact_submissions')
          .doc(submissionId)
          .update({'read': true});
    } catch (e) {
      debugPrint('[ContactFormService] Error marking as read: $e');
      rethrow;
    }
  }

  // Mark submission as replied
  Future<void> markAsReplied(String submissionId) async {
    try {
      await _firestore
          .collection('contact_submissions')
          .doc(submissionId)
          .update({'replied': true});
    } catch (e) {
      debugPrint('[ContactFormService] Error marking as replied: $e');
      rethrow;
    }
  }

  // Delete submission
  Future<void> deleteSubmission(String submissionId) async {
    try {
      await _firestore
          .collection('contact_submissions')
          .doc(submissionId)
          .delete();
    } catch (e) {
      debugPrint('[ContactFormService] Error deleting submission: $e');
      rethrow;
    }
  }

  // Track resume download
  Future<void> trackResumeDownload({
    required String userAgent,
    String? ipAddress,
  }) async {
    try {
      await _firestore.collection('resume_downloads').add({
        'timestamp': FieldValue.serverTimestamp(),
        'userAgent': userAgent,
        'ipAddress': ipAddress ?? 'unknown',
      });
      debugPrint('[ContactFormService] Resume download tracked');
    } catch (e) {
      debugPrint('[ContactFormService] Error tracking download: $e');
    }
  }

  // Get resume download stats
  Future<Map<String, dynamic>> getResumeDownloadStats() async {
    try {
      final snapshot = await _firestore.collection('resume_downloads').get();

      final total = snapshot.docs.length;
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      int todayCount = 0;
      for (var doc in snapshot.docs) {
        final timestamp = (doc.data()['timestamp'] as Timestamp?)?.toDate();
        if (timestamp != null && timestamp.isAfter(todayStart)) {
          todayCount++;
        }
      }

      return {
        'total': total,
        'today': todayCount,
      };
    } catch (e) {
      debugPrint('[ContactFormService] Error getting stats: $e');
      return {'total': 0, 'today': 0};
    }
  }
}
