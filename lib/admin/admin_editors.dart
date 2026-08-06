import 'package:flutter/material.dart';

import '../models/project_model.dart';
import '../services/firebase_service.dart';
import '../widgets/project_card.dart';
import '../utils/url_utils.dart';

mixin AdminEditors<T extends StatefulWidget> on State<T> {
  List<Project> get projects;
  Map<String, TextEditingController> get sectionCtrls;
  List<Map<String, String>> get sectionList;
  Map<String, Map<String, TextEditingController>> get listItemCtrls;
  String get selectedSection;

  TextEditingController _getListCtrl(String id, String key,
      {String initial = ''}) {
    final map = listItemCtrls.putIfAbsent(id, () => {});
    return map.putIfAbsent(key, () => TextEditingController(text: initial));
  }

  Widget buildProjectsEditor() {
    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            itemCount: projects.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = projects.removeAt(oldIndex);
                projects.insert(newIndex, item);
              });
            },
            itemBuilder: (ctx, i) {
              final p = projects[i];
              return ListTile(
                key: ValueKey(p.id),
                title: InkWell(
                  onTap: () => openEditor(project: p, index: i),
                  child: ProjectCard(project: p),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: ctx,
                      builder: (c) => AlertDialog(
                        title: const Text('Confirm delete'),
                        content: const Text('Delete this project?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(c).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(c).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      setState(() => projects.removeAt(i));
                      try {
                        await FirebaseService().deleteProject(p.id);
                      } catch (_) {}
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void openEditor({Project? project, int? index}) {
    final editing = project ??
        Project(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: '',
          description: '',
          image:
              'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=1200&q=80',
          tech: [],
        );

    showDialog(
      context: context,
      builder: (ctx) {
        final titleCtrl = TextEditingController(text: editing.title);
        final descCtrl = TextEditingController(text: editing.description);
        final imageCtrl = TextEditingController(text: editing.image);
        final githubCtrl = TextEditingController(text: editing.github ?? '');
        final demoCtrl = TextEditingController(text: editing.demo ?? '');
        final techCtrl = TextEditingController(text: editing.tech.join(', '));

        return AlertDialog(
          title: Text(project == null ? 'Add Project' : 'Edit Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    color: Colors.grey.shade200,
                    child: imageCtrl.text.isNotEmpty
                        ? Image.network(
                            UrlUtils.sanitizeUrl(imageCtrl.text) ??
                                imageCtrl.text,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const Center(child: Icon(Icons.broken_image)),
                          )
                        : const Center(child: Icon(Icons.image)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: imageCtrl,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: techCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Tech (comma separated)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: githubCtrl,
                  decoration:
                      const InputDecoration(labelText: 'GitHub URL (optional)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: demoCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Demo URL (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate URLs before accepting
                bool ok = true;
                String err = '';
                bool validate(String? u) {
                  if (u == null || u.isEmpty) return true;
                  try {
                    final uri = Uri.parse(u);
                    return uri.isAbsolute &&
                        (uri.scheme == 'http' || uri.scheme == 'https');
                  } catch (_) {
                    return false;
                  }
                }

                if (!validate(githubCtrl.text.trim())) {
                  ok = false;
                  err = 'Invalid GitHub URL';
                }
                if (!validate(demoCtrl.text.trim())) {
                  ok = false;
                  err = 'Invalid Demo URL';
                }
                if (!ok) {
                  ScaffoldMessenger.of(ctx)
                      .showSnackBar(SnackBar(content: Text(err)));
                  return;
                }

                final newProject = Project(
                  id: editing.id,
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  image: imageCtrl.text.trim().isEmpty
                      ? 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=1200&q=80'
                      : imageCtrl.text.trim(),
                  tech: techCtrl.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList(),
                  github: githubCtrl.text.trim().isEmpty
                      ? null
                      : githubCtrl.text.trim(),
                  demo: demoCtrl.text.trim().isEmpty
                      ? null
                      : demoCtrl.text.trim(),
                );
                setState(() {
                  if (project != null && index != null) {
                    projects[index] = newProject;
                  } else {
                    projects.insert(0, newProject);
                  }
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget buildTypedEditor() {
    if (selectedSection == 'about') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: sectionCtrls['title'],
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: TextField(
              controller: sectionCtrls['body'],
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(labelText: 'Body'),
            ),
          ),
        ],
      );
    } else if (selectedSection == 'contact') {
      return Column(
        children: [
          TextField(
            controller: sectionCtrls['email'],
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: sectionCtrls['phone'],
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: sectionCtrls['location'],
            decoration: const InputDecoration(labelText: 'Location'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: sectionCtrls['social'],
            decoration: const InputDecoration(
                labelText: 'Social links (comma separated)'),
          ),
        ],
      );
    } else if (selectedSection == 'home') {
      return Column(
        children: [
          TextField(
            controller: sectionCtrls['hero'],
            decoration: const InputDecoration(labelText: 'Hero title'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: sectionCtrls['subtitle'],
            decoration: const InputDecoration(labelText: 'Subtitle'),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget buildListEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sectionList.length,
          itemBuilder: (c, i) {
            final item = sectionList[i];
            final id = item['id']!;
            final titleCtrl =
                _getListCtrl(id, 'title', initial: item['title'] ?? '');
            final shortCtrl =
                _getListCtrl(id, 'short', initial: item['short'] ?? '');
            final linkCtrl =
                _getListCtrl(id, 'link', initial: item['link'] ?? '');
            final linkTextCtrl =
                _getListCtrl(id, 'linkText', initial: item['linkText'] ?? '');

            return ListTile(
              key: ValueKey(id),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                    onChanged: (v) => setState(() => item['title'] = v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: linkTextCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Link text (optional)'),
                    onChanged: (v) => setState(() => item['linkText'] = v),
                  ),
                ],
              ),
              subtitle: Column(
                children: [
                  TextField(
                    controller: shortCtrl,
                    decoration: const InputDecoration(labelText: 'Short'),
                    onChanged: (v) => setState(() => item['short'] = v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: linkCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Link (URL, optional)'),
                    onChanged: (v) => setState(() => item['link'] = v),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: c,
                    builder: (cc) => AlertDialog(
                      title: const Text('Confirm delete'),
                      content: const Text('Delete this item?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(cc).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(cc).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    setState(() {
                      sectionList.removeAt(i);
                      final removed = listItemCtrls.remove(id);
                      if (removed != null) {
                        for (final ctrl in removed.values) {
                          ctrl.dispose();
                        }
                      }
                    });
                  }
                },
              ),
            );
          },
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = sectionList.removeAt(oldIndex);
              sectionList.insert(newIndex, item);
            });
          },
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {
            final id = DateTime.now().millisecondsSinceEpoch.toString();
            setState(() {
              sectionList.insert(0, {
                'id': id,
                'title': 'New',
                'short': '',
                'link': '',
                'linkText': ''
              });
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Item'),
        ),
      ],
    );
  }
}
