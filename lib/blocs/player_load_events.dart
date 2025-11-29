import 'package:playbloc/blocs/player_event.dart';


class PlayerLoadEvent extends PlayerEvent {
  final int index;
  const PlayerLoadEvent(this.index);

  @override
  List<Object> get props => [index];
}


class PlayEvent extends PlayerEvent {
  const PlayEvent();
}


class PauseEvent extends PlayerEvent {
  const PauseEvent();
}


class NextEvent extends PlayerEvent {
  const NextEvent();
}


class PrevEvent extends PlayerEvent {
  const PrevEvent();
}


class PlayPauseEvent extends PlayerEvent {
  const PlayPauseEvent();
}


class SeekEvent extends PlayerEvent {
  final Duration position;
  const SeekEvent(this.position);

  @override
  List<Object> get props => [position];
}


class VolumeChangeEvent extends PlayerEvent {
  final double volume;
  const VolumeChangeEvent(this.volume);

  @override
  List<Object> get props => [volume];
}


class PitchChangeEvent extends PlayerEvent {
  final double pitch;
  const PitchChangeEvent(this.pitch);

  @override
  List<Object> get props => [pitch];
}


class AddInternetTrackEvent extends PlayerEvent {
  final Map<String, dynamic> trackData;
  const AddInternetTrackEvent(this.trackData);

  @override
  List<Object> get props => [trackData];
}