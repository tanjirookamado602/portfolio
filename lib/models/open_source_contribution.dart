class OpenSourceContribution {
  final String id;
  final String repoName;
  final String description;
  final String prLink;
  final List<String> tags;
  final int? mergedPrCount;
  final int order;

  OpenSourceContribution({
    required this.id,
    required this.repoName,
    required this.description,
    required this.prLink,
    required this.tags,
    this.mergedPrCount,
    required this.order,
  });

  factory OpenSourceContribution.fromMap(String id, Map<String, dynamic> map) {
    return OpenSourceContribution(
      id: id,
      repoName: map['repoName'] ?? '',
      description: map['description'] ?? '',
      prLink: map['prLink'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      mergedPrCount: map['mergedPrCount'] != null ? int.tryParse(map['mergedPrCount'].toString()) : null,
      order: int.tryParse(map['order'].toString()) ?? 999,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'repoName': repoName,
      'description': description,
      'prLink': prLink,
      'tags': tags,
      'mergedPrCount': mergedPrCount,
      'order': order,
    };
  }
}
