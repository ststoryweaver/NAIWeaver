class GalleryAlbum {
  final String id;
  final String name;
  final Set<String> imageBasenames;

  GalleryAlbum({
    required this.id,
    required this.name,
    Set<String>? imageBasenames,
  }) : imageBasenames = imageBasenames ?? {};

  GalleryAlbum copyWith({String? name, Set<String>? imageBasenames}) {
    return GalleryAlbum(
      id: id,
      name: name ?? this.name,
      imageBasenames: imageBasenames ?? this.imageBasenames,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imageBasenames': imageBasenames.toList(),
      };

  factory GalleryAlbum.fromJson(Map<String, dynamic> json) => GalleryAlbum(
        id: json['id'] as String,
        name: json['name'] as String,
        imageBasenames: (json['imageBasenames'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toSet() ??
            {},
      );
}
