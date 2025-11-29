class AudioTrack {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String url;
  final Duration duration;
  final String? imageUrl;

  AudioTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.url,
    required this.duration,
    this.imageUrl,
  });

  factory AudioTrack.fromMap(Map<String, dynamic> map) {
    return AudioTrack(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: map['album'] as String,
      url: map['url'] as String,
      duration: Duration(seconds: map['duration'] as int),
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'url': url,
      'duration': duration.inSeconds,
      'imageUrl': imageUrl,
    };
  }
}

