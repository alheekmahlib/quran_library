class BookmarkModel {
  final int id;
  final int colorCode;
  int ayahId;
  int ayahNumber;
  int page;
  final String name;

  BookmarkModel({
    required this.id,
    required this.colorCode,
    required this.name,
    this.ayahId = -1,
    this.ayahNumber = -1,
    this.page = -1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ayahId': ayahId,
        'ayahNumber': ayahNumber,
        'page': page,
        'color': colorCode,
        'name': name,
      };

  factory BookmarkModel.fromJson(Map<String, dynamic> json) => BookmarkModel(
        id: json['id'],
        colorCode: json['color'],
        name: json['name'] ?? 'Unnamed Bookmark',
        ayahId: json['ayahId'] ?? -1,
        ayahNumber: json['ayahNumber'] ?? -1,
        page: json['page'] ?? -1,
      );
}
