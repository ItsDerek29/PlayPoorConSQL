class AudioItem {
  final int? id;
  final String assetPath;
  final String title;
  final String artist;
  final String imagePath;

  AudioItem(
    this.assetPath,
    this.title,
    this.artist,
    this.imagePath, {
    this.id,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assetPath': assetPath,
      'title': title,
      'artist': artist,
      'imagePath': imagePath,
    };
  }

  factory AudioItem.fromMap(Map<String, dynamic> map) {
    return AudioItem(
      map['assetPath'],
      map['title'],
      map['artist'],
      map['imagePath'],
      id: map['id'],
    );
  }
}