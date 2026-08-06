import 'dart:convert';

class Project {
  final String id;
  String title;
  String description;
  String image;
  List<String> tech;
  String? github;
  String? demo;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.tech,
    this.github,
    this.demo,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] ?? (json['title'] ?? '').toString().toLowerCase().replaceAll(' ', '_'),
        title: json['title'] ?? '',
        description: json['short'] ?? json['description'] ?? '',
  // Normalize image paths: if older JSON referenced local assets (e.g. "assets/projects/...")
  // convert those to a stable network placeholder to avoid 404s on web builds.
  image: (() {
    final raw = json['image']?.toString() ?? '';
    if (raw.isEmpty) return 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=1200&q=80';
    // If the image looks like a bundled asset path, return a placeholder URL instead.
    if (raw.startsWith('assets/') || raw.startsWith('assets\\') || raw.contains('flutter_assets')) {
      return 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=1200&q=80';
    }
    return raw;
  })(),
        tech: (json['tech'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        github: json['github'] ?? json['source'] ?? '',
        demo: json['demo'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'short': description,
        'image': image,
        'tech': tech,
        'github': github,
        'demo': demo,
      };

  static List<Project> listFromJson(String jsonStr) {
    final src = json.decode(jsonStr);
    if (src is List) return src.map((e) => Project.fromJson(e)).toList();
    if (src is Map && src['projects'] != null) {
      return (src['projects'] as List).map((e) => Project.fromJson(e)).toList();
    }
    return [];
  }
}
