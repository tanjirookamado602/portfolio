import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';

class ProjectService {
  static const _prefsKey = 'projects_data_v1';

  Future<List<Project>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefsKey);
    if (cached != null) {
      try {
        return Project.listFromJson(cached);
      } catch (_) {}
    }

    final raw = await rootBundle.loadString('assets/data/projects.json');
    return Project.listFromJson(raw);
  }

  Future<void> saveProjects(List<Project> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(projects.map((p) => p.toJson()).toList());
    await prefs.setString(_prefsKey, jsonStr);
  }
}
