import 'package:playbloc/blocs/payer_state.dart';


class IniState extends PlayState {
  const IniState();
}


class LoadingState extends PlayState {
  final int? currentIndex;
  final Duration? duration;
  final Duration? position;
  final bool? playing;
  final int playlistSignature;

  const LoadingState({
    this.currentIndex,
    this.duration,
    this.position,
    this.playing,
    this.playlistSignature = 0,
  });

  @override
  List<Object?> get props => [currentIndex, duration, position, playing, playlistSignature];
}


class PlayingState extends PlayState {
  final int currentIndex;
  final Duration duration;
  final Duration position;
  final bool playing;
  final double volume;
  final double pitch;
  final int playlistSignature;

  const PlayingState({
    required this.currentIndex,
    required this.duration,
    required this.position,
    required this.playing,
    this.volume = 1.0,
    this.pitch = 1.0,
    this.playlistSignature = 0,
  });

  @override
  List<Object> get props => [currentIndex, duration, position, playing, volume, pitch, playlistSignature];

  PlayingState copyWith({
    int? currentIndex,
    Duration? duration,
    Duration? position,
    bool? playing,
    double? volume,
    double? pitch,
    int? playlistSignature,
  }) {
    return PlayingState(
      currentIndex: currentIndex ?? this.currentIndex,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      playing: playing ?? this.playing,
      volume: volume ?? this.volume,
      pitch: pitch ?? this.pitch,
      playlistSignature: playlistSignature ?? this.playlistSignature,
    );
  }
}


class ErrorState extends PlayState {
  final String msg;

  const ErrorState(this.msg);
  
  @override
  List<Object> get props => [msg];
}