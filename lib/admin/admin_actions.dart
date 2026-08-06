import 'package:flutter/material.dart';

mixin AdminActions<T extends StatefulWidget> on State<T> {
  Map<String, TextEditingController> get sectionCtrls;
  List<Map<String, String>> get sectionList;
  String get selectedSection;

  void handleAddAction() {
    if (selectedSection == 'projects') {
      (this as dynamic).openEditor();
    } else if (isTypedSection(selectedSection)) {
      showTypedSectionEditorDialog();
    } else {
      showAddListItemDialog();
    }
  }

  bool isTypedSection(String s) => ['about', 'contact', 'home'].contains(s);

  void showAddListItemDialog() {
    final titleCtrl = TextEditingController(text: 'New');
    final shortCtrl = TextEditingController(text: '');

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Add item to $selectedSection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: shortCtrl,
              decoration: const InputDecoration(labelText: 'Short'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final id = DateTime.now().millisecondsSinceEpoch.toString();
              setState(() {
                sectionList.insert(0, {
                  'id': id,
                  'title': titleCtrl.text.trim(),
                  'short': shortCtrl.text.trim(),
                });
              });
              Navigator.of(c).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void showTypedSectionEditorDialog() {
    // Ensure controllers exist
    if (selectedSection == 'about') {
      sectionCtrls.putIfAbsent('title', () => TextEditingController());
      sectionCtrls.putIfAbsent('body', () => TextEditingController());
    } else if (selectedSection == 'contact') {
      sectionCtrls.putIfAbsent('email', () => TextEditingController());
      sectionCtrls.putIfAbsent('phone', () => TextEditingController());
      sectionCtrls.putIfAbsent('location', () => TextEditingController());
      sectionCtrls.putIfAbsent('social', () => TextEditingController());
    } else if (selectedSection == 'home') {
      sectionCtrls.putIfAbsent('hero', () => TextEditingController());
      sectionCtrls.putIfAbsent('subtitle', () => TextEditingController());
    }

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Edit $selectedSection'),
        content:
            SingleChildScrollView(child: (this as dynamic).buildTypedEditor()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(c);
              await (this as dynamic).saveSectionLocally();
              if (!mounted) return;
              nav.pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
