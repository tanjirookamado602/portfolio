import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/local_content_service.dart';
import '../services/firebase_service.dart';

mixin AdminHelpers<T extends StatefulWidget> on State<T> {
  LocalContentService get contentService;
  Map<String, TextEditingController> get sectionCtrls;
  List<Map<String, String>> get sectionList;
  String get selectedSection;

  bool isTypedSection(String s) => ['about', 'contact', 'home'].contains(s);

  Future<void> loadSection(String section) async {
    final raw = await contentService.loadRaw(section);
    if (!mounted) return;

    setState(() {
      sectionCtrls.clear();
      sectionList.clear();
    });

    if (raw == null) return;

    try {
      final parsed = json.decode(raw);
      if (section == 'about') {
        setState(() {
          sectionCtrls['title'] =
              TextEditingController(text: parsed['title'] ?? '');
          sectionCtrls['body'] =
              TextEditingController(text: parsed['body'] ?? '');
        });
      } else if (section == 'contact') {
        setState(() {
          sectionCtrls['email'] =
              TextEditingController(text: parsed['email'] ?? '');
          sectionCtrls['phone'] =
              TextEditingController(text: parsed['phone'] ?? '');
          sectionCtrls['location'] =
              TextEditingController(text: parsed['location'] ?? '');
          sectionCtrls['social'] =
              TextEditingController(text: parsed['social'] ?? '');
        });
      } else if (section == 'home') {
        setState(() {
          sectionCtrls['hero'] =
              TextEditingController(text: parsed['hero'] ?? '');
          sectionCtrls['subtitle'] =
              TextEditingController(text: parsed['subtitle'] ?? '');
        });
      } else if (parsed is Map && parsed['items'] is List) {
        setState(() {
          sectionList.addAll(List<Map<String, String>>.from(
              (parsed['items'] as List)
                  .map((e) => Map<String, String>.from(e))));
        });
      }
    } catch (_) {}
  }

  Future<void> saveSectionLocally() async {
    // perform save then show messenger (avoid using context across awaits)
    Map<String, dynamic> out = {};

    if (isTypedSection(selectedSection)) {
      if (selectedSection == 'about') {
        out = {
          'title': sectionCtrls['title']?.text ?? '',
          'body': sectionCtrls['body']?.text ?? '',
        };
      } else if (selectedSection == 'contact') {
        out = {
          'email': sectionCtrls['email']?.text ?? '',
          'phone': sectionCtrls['phone']?.text ?? '',
          'location': sectionCtrls['location']?.text ?? '',
          'social': sectionCtrls['social']?.text ?? '',
        };
      } else if (selectedSection == 'home') {
        out = {
          'hero': sectionCtrls['hero']?.text ?? '',
          'subtitle': sectionCtrls['subtitle']?.text ?? '',
        };
      }
    } else {
      out = {'items': sectionList};
    }

    await contentService.saveRaw(selectedSection, json.encode(out));
  if (!mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(const SnackBar(content: Text('Section saved locally')));
  }

  Future<void> pushSectionToRemote() async {
    try {
      Map<String, dynamic> out = {};

      if (isTypedSection(selectedSection)) {
        if (selectedSection == 'about') {
          out = {
            'title': sectionCtrls['title']?.text ?? '',
            'body': sectionCtrls['body']?.text ?? '',
          };
        } else if (selectedSection == 'contact') {
          out = {
            'email': sectionCtrls['email']?.text ?? '',
            'phone': sectionCtrls['phone']?.text ?? '',
            'location': sectionCtrls['location']?.text ?? '',
            'social': sectionCtrls['social']?.text ?? '',
          };
        } else if (selectedSection == 'home') {
          out = {
            'hero': sectionCtrls['hero']?.text ?? '',
            'subtitle': sectionCtrls['subtitle']?.text ?? '',
          };
        }
      } else {
        out = {'items': sectionList};
      }

      await FirebaseService()
          .pushCollectionRaw(selectedSection, {'content': out});
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(const SnackBar(content: Text('Section pushed to Firestore')));
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text('Push failed: $e')));
    }
  }
}
