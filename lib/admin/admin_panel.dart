import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';
import '../services/firebase_service.dart';
import '../services/local_content_service.dart';
import '../theme/app_theme.dart';
import 'admin_helpers.dart';
import 'admin_actions.dart';
import 'admin_editors.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel>
    with AdminHelpers, AdminActions, AdminEditors {
  final ProjectService _service = ProjectService();
  @override
  final LocalContentService contentService = LocalContentService();

  @override
  List<Project> projects = [];
  bool _loading = true;

  static const List<String> _sections = [
    'projects',
    'about',
    'contact',
    'home',
    'skills',
    'hackathons',
    'certifications',
    'volunteer'
  ];

  @override
  String selectedSection = 'projects';

  @override
  final Map<String, TextEditingController> sectionCtrls = {};

  @override
  List<Map<String, String>> sectionList = [];

  @override
  final Map<String, Map<String, TextEditingController>> listItemCtrls = {};

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      projects = await _service.loadProjects();
      await loadSection(selectedSection);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _exportJson() {
    final s = projects.map((p) => p.toJson()).toList();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(s);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Export JSON'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(child: SelectableText(jsonStr)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _importJsonDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Import JSON'),
        content: SizedBox(
          width: 600,
          child: TextField(
            controller: ctrl,
            maxLines: 12,
            decoration: const InputDecoration(
                hintText: 'Paste projects JSON array or object here'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final parsed = Project.listFromJson(ctrl.text);
                setState(() => projects = parsed);
                Navigator.of(c).pop();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid JSON')),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  // Authentication is requested when opening the Admin panel from the
  // site navigation. Individual sync actions do not prompt for login here.

  Future<void> _saveProjectsLocally() async {
    await _service.saveProjects(projects);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Projects saved locally')),
    );
  }

  Future<void> _pushToFirestore() async {
    try {
      await FirebaseService().pushProjects(projects);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Projects synced to Firestore')),
      );
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text('Sync failed: $e')));
    }
  }

  Future<void> _loadFromFirestore() async {
    try {
      final remote = await FirebaseService().fetchProjects();
      if (!mounted) return;
      setState(() => projects = remote);
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Loaded projects from Firestore')),
      );
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text('Load failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final topControls = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: handleAddAction,
            icon: const Icon(Icons.add),
            label: Text(
                'Add ${selectedSection[0].toUpperCase()}${selectedSection.substring(1)}'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _exportJson,
            child: const Text('Export JSON'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _importJsonDialog,
            child: const Text('Import JSON'),
          ),
          const Spacer(),
          DropdownButton<String>(
            value: selectedSection,
            items: _sections
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s),
                    ))
                .toList(),
            onChanged: (v) async {
              if (v == null) return;
              setState(() => selectedSection = v);
              await loadSection(v);
            },
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async => await loadSection(selectedSection),
            child: const Text('Load Section (local)'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: pushSectionToRemote,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Sync to Firestore'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _loadFromFirestore,
            icon: const Icon(Icons.cloud_download),
            label: const Text('Load from Firestore'),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: topControls,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(AppTheme.responsivePadding(context)),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selectedSection == 'projects')
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.6,
                              ),
                              child: buildProjectsEditor(),
                            )
                          else if (isTypedSection(selectedSection))
                            Card(
                              color: AppTheme.cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: buildTypedEditor(),
                              ),
                            )
                          else
                            Card(
                              color: AppTheme.cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: buildListEditor(),
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _loadInitial,
                          child: const Text('Reload'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            if (selectedSection == 'projects') {
                              // online-first: push to Firestore then save locally on success
                              try {
                                await _pushToFirestore();
                                await _saveProjectsLocally();
                              } catch (e) {
                                if (!mounted) return;
                                // show snackbar after ensuring mounted
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Failed to sync projects: $e')));
                                });
                              }
                            } else {
                              try {
                                await pushSectionToRemote();
                                await saveSectionLocally();
                              } catch (e) {
                                if (!mounted) return;
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Failed to sync section: $e')));
                                });
                              }
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (final controller in sectionCtrls.values) {
      controller.dispose();
    }
    for (final itemMap in listItemCtrls.values) {
      for (final controller in itemMap.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }
}
