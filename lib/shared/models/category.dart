class Category {
  const Category({
    required this.id,
    required this.name,
    this.parentId,
  });

  final String id;
  final String name;
  final String? parentId;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      parentId: json['parentId']?.toString() ?? json['parent_id']?.toString(),
    );
  }
}
