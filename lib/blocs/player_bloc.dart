import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:playbloc/blocs/payer_state.dart';
import 'package:playbloc/blocs/player_event.dart';
import 'package:playbloc/blocs/player_load_events.dart';
import 'package:playbloc/blocs/player_load_states.dart';
import 'package:playbloc/models/audio_item.dart';
import 'package:playbloc/models/audio_track.dart';


enum TrackType { local, internet }

class PlayerBloc extends Bloc<PlayerEvent, PlayState> {
  final AudioPlayer audioPlayer;
  final List<AudioItem> items;

  StreamSubscription<Duration>? posicion;
  StreamSubscription<Duration>? duracion;
  StreamSubscription<PlayerState>? estado;
  

  bool _isManualPause = false;

  PlayerBloc({
    required this.audioPlayer,
    required this.items,
  }) : super(const IniState()) {
    on<PlayerLoadEvent>(_onPlayerLoadEvent);
    on<PlayEvent>(_onPlayEvent);
    on<PauseEvent>(_onPauseEvent);
    on<PlayPauseEvent>(_onPlayPauseEvent);
    on<NextEvent>(_onNextEvent);
    on<PrevEvent>(_onPrevEvent);
    on<SeekEvent>(_onSeekEvent);
    on<VolumeChangeEvent>(_onVolumeChangeEvent);
    on<PitchChangeEvent>(_onPitchChangeEvent);
    on<AddInternetTrackEvent>(_onAddInternetTrackEvent);
    on<RemoveLastItemEvent>(_onRemoveLastItemEvent);
    on<_PositionUpdateEvent>(_onPositionUpdate);
    on<_DurationUpdateEvent>(_onDurationUpdate);
    on<_PlayerStateUpdateEvent>(_onPlayerStateUpdate);
    
    _setupListeners();
  }


  int get totalCanciones => items.length;


  TrackType _getTrackType(int index) {
    if (index >= 0 && index < items.length) {
      final path = items[index].assetPath;
      if (path.startsWith('http')) {
        return TrackType.internet;
      }
      return TrackType.local;
    }
    return TrackType.local;
  }


  String getTrackTitle(int index) {
    if (index >= 0 && index < items.length) {
      return items[index].title;
    }
    return "Unknown";
  }


  String getTrackArtist(int index) {
    if (index >= 0 && index < items.length) {
      return items[index].artist;
    }
    return "Unknown";
  }


  String? getTrackImage(int index) {
    if (index >= 0 && index < items.length) {
      return items[index].imagePath;
    }
    return null;
  }


  AudioItem? getLocalTrack(int index) {
    if (index >= 0 && index < items.length) {
      return items[index];
    }
    return null;
  }



  void _onPositionUpdate(_PositionUpdateEvent event, Emitter<PlayState> emit) {
    if (state is PlayingState) {
      final currentState = state as PlayingState;
      emit(currentState.copyWith(position: event.position));
    }
  }

  void _onDurationUpdate(_DurationUpdateEvent event, Emitter<PlayState> emit) {
    if (state is PlayingState) {
      final currentState = state as PlayingState;
      emit(currentState.copyWith(duration: event.duration));
    } else if (state is LoadingState) {
      final loadingState = state as LoadingState;
      emit(LoadingState(
        currentIndex: loadingState.currentIndex,
        duration: event.duration,
        position: loadingState.position,
        playing: loadingState.playing,
        playlistSignature: loadingState.playlistSignature,
      ));
    }
  }

  void _onPlayerStateUpdate(_PlayerStateUpdateEvent event, Emitter<PlayState> emit) {
    if (state is PlayingState) {
      final currentState = state as PlayingState;

      if (!_isManualPause || event.isPlaying) {
        emit(currentState.copyWith(playing: event.isPlaying));
        if (event.isPlaying) {
          _isManualPause = false;
        }
      }
    }
  }


  FutureOr<void> _onRemoveLastItemEvent(
    RemoveLastItemEvent event,
    Emitter<PlayState> emit,
  ) async {
    if (items.isNotEmpty) {
      final removedIndex = items.length - 1;
      items.removeLast();
      
      final currentState = state;
      int? currentIndex;
      
      if (currentState is PlayingState) {
        currentIndex = currentState.currentIndex;
      } else if (currentState is LoadingState) {
        currentIndex = currentState.currentIndex;
      }
      
      // If we removed the currently playing song
      if (currentIndex != null && currentIndex == removedIndex) {
        await audioPlayer.stop();
        // Go to previous if possible, or 0, or stop
        if (items.isNotEmpty) {
           final newIndex = (removedIndex - 1 + items.length) % items.length;
           add(PlayerLoadEvent(newIndex));
        } else {
          // List empty
          emit(const IniState());
        }
      } else if (currentIndex != null && currentIndex > removedIndex) {
         // Should not happen if we remove last, unless index was somehow out of bounds
      } else {
        // Just update signature to refresh UI if needed (though UI might not react if only list changed)
        // But since we pass `items` to UI widgets, they might need a rebuild.
        // Emitting a new state with same values but different signature helps.
        if (currentState is PlayingState) {
          emit(currentState.copyWith(
            playlistSignature: currentState.playlistSignature + 1,
          ));
        } else if (currentState is LoadingState) {
          emit(LoadingState(
            currentIndex: currentState.currentIndex,
            duration: currentState.duration,
            position: currentState.position,
            playing: currentState.playing,
            playlistSignature: currentState.playlistSignature + 1,
          ));
        }
      }
    }
  }

  FutureOr<void> _onAddInternetTrackEvent(
    AddInternetTrackEvent event,
    Emitter<PlayState> emit,
  ) async {
    try {
      final item = AudioItem(
        event.trackData['assetPath'],
        event.trackData['title'],
        event.trackData['artist'],
        event.trackData['imagePath'] ?? '',
        id: int.tryParse(event.trackData['id'].toString()),
      );
      
      items.add(item);
      
      final currentState = state;
      if (currentState is PlayingState) {
        emit(currentState.copyWith(
          playlistSignature: currentState.playlistSignature + 1,
        ));
      } else if (currentState is LoadingState) {
        emit(LoadingState(
          currentIndex: currentState.currentIndex,
          duration: currentState.duration,
          position: currentState.position,
          playing: currentState.playing,
          playlistSignature: currentState.playlistSignature + 1,
        ));
      }
    } catch (e) {
      debugPrint("Error agregando canción de internet: ${e.toString()}");
    }
  }

  FutureOr<void> _onPlayerLoadEvent(
    PlayerLoadEvent event,
    Emitter<PlayState> emit,
  ) async {
    try {
      if (event.index < 0 || event.index >= totalCanciones) {
        emit(ErrorState("Invalid track index"));
        return;
      }

      emit(LoadingState(currentIndex: event.index));
      

      try {
        await audioPlayer.stop();
      } catch (e) {
        debugPrint("Error stopping player: ${e.toString()}");
      }
      
      final trackType = _getTrackType(event.index);

      try {
        if (trackType == TrackType.local) {
          await audioPlayer.setSourceAsset(items[event.index].assetPath);
        } else {
          await audioPlayer.setSourceUrl(items[event.index].assetPath);
        }
      } catch (e) {
        emit(ErrorState("Error: No se pudo cargar el archivo: ${e.toString()}"));
        debugPrint("Error loading source: ${e.toString()}");
        return;
      }


      await Future.delayed(const Duration(milliseconds: 200));

      Duration? currentDuration;
      Duration currentPosition = Duration.zero;
      
      int retries = 3;
      while (retries > 0) {
        try {
          final duration = await audioPlayer.getDuration();
          if (duration != null && duration.inMilliseconds > 0) {
            currentDuration = duration;
            break;
          }
        } catch (e) {
          debugPrint("Error getting duration (retries: $retries): ${e.toString()}");
        }
        if (retries > 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        retries--;
      }
      
      if (currentDuration == null || currentDuration.inMilliseconds == 0) {
        currentDuration = Duration.zero;
      }

      double volume = 1.0;
      double pitch = 1.0;
      if (state is PlayingState) {
        final prevState = state as PlayingState;
        volume = prevState.volume;
        pitch = prevState.pitch;
      }

      emit(PlayingState(
        currentIndex: event.index,
        duration: currentDuration,
        position: currentPosition,
        playing: false,
        volume: volume,
        pitch: pitch,
        playlistSignature: state is PlayingState ? (state as PlayingState).playlistSignature : (state is LoadingState ? (state as LoadingState).playlistSignature : 0),
      ));

      await Future.delayed(const Duration(milliseconds: 100));
      add(const PlayEvent());
    } catch (e) {
      emit(ErrorState("Error: No se pudo cargar el archivo: ${e.toString()}"));
      debugPrint("Error in _onPlayerLoadEvent: ${e.toString()}");
    }
  }

  FutureOr<void> _onPlayEvent(
    PlayEvent event,
    Emitter<PlayState> emit,
  ) async {
    try {
      if (state is PlayingState) {
        final currentState = state as PlayingState;
        try {
          await audioPlayer.resume();
          emit(currentState.copyWith(playing: true));
          _isManualPause = false;
        } catch (e) {
          debugPrint("Error resuming playback: ${e.toString()}");
          try {
            final trackType = _getTrackType(currentState.currentIndex);
            if (trackType == TrackType.local) {
              await audioPlayer.setSourceAsset(items[currentState.currentIndex].assetPath);
            } else {
              await audioPlayer.setSourceUrl(items[currentState.currentIndex].assetPath);
            }
            await audioPlayer.resume();
            emit(currentState.copyWith(playing: true));
            _isManualPause = false;
          } catch (e2) {
            debugPrint("Error playing from start: ${e2.toString()}");
            emit(ErrorState("Error: No se pudo reproducir el archivo: ${e2.toString()}"));
          }
        }
      } else if (state is LoadingState) {
        final loadingState = state as LoadingState;
        if (loadingState.currentIndex != null) {
          try {
            await audioPlayer.resume();
            emit(PlayingState(
              currentIndex: loadingState.currentIndex!,
              duration: loadingState.duration ?? Duration.zero,
              position: loadingState.position ?? Duration.zero,
              playing: true,
              volume: 1.0,
              pitch: 1.0,
              playlistSignature: loadingState.playlistSignature,
            ));
            _isManualPause = false;
          } catch (e) {
            debugPrint("Error resuming from loading state: ${e.toString()}");
          }
        }
      }
    } catch (e) {
      debugPrint("Error in _onPlayEvent: ${e.toString()}");
    }
  }

  FutureOr<void> _onPauseEvent(
    PauseEvent event,
    Emitter<PlayState> emit,
  ) async {
    try {
      if (state is PlayingState) {
        final currentState = state as PlayingState;
        _isManualPause = true;
        await audioPlayer.pause();
        emit(currentState.copyWith(playing: false));
      }
    } catch (e) {
      emit(ErrorState("Error: No se pudo pausar: ${e.toString()}"));
      debugPrint(e.toString());
    }
  }

  FutureOr<void> _onPlayPauseEvent(
    PlayPauseEvent event,
    Emitter<PlayState> emit,
  ) async {
    if (state is PlayingState) {
      final currentState = state as PlayingState;
      if (currentState.playing) {
        add(const PauseEvent());
      } else {
        add(const PlayEvent());
      }
    }
  }

  FutureOr<void> _onNextEvent(
    NextEvent event,
    Emitter<PlayState> emit,
  ) async {
    if (totalCanciones == 0) {
      emit(ErrorState("No songs available"));
      return;
    }
    
    int? currentIndex;
    final currentState = state;
    if (currentState is PlayingState) {
      currentIndex = currentState.currentIndex;
    } else if (currentState is LoadingState) {
      currentIndex = currentState.currentIndex;
    }
    
    if (currentIndex != null) {
      // Ensure current index is valid
      if (currentIndex >= totalCanciones) {
        currentIndex = 0;
      }
      final nextIndex = (currentIndex + 1) % totalCanciones;
      add(PlayerLoadEvent(nextIndex));
    }
  }

  FutureOr<void> _onPrevEvent(
    PrevEvent event,
    Emitter<PlayState> emit,
  ) async {
    if (totalCanciones == 0) {
      emit(ErrorState("No songs available"));
      return;
    }
    
    int? currentIndex;
    final currentState = state;
    if (currentState is PlayingState) {
      currentIndex = currentState.currentIndex;
    } else if (currentState is LoadingState) {
      currentIndex = currentState.currentIndex;
    }
    
    if (currentIndex != null) {
      // Ensure current index is valid
      if (currentIndex >= totalCanciones) {
        currentIndex = 0;
      }
      final prevIndex = (currentIndex - 1 + totalCanciones) % totalCanciones;
      add(PlayerLoadEvent(prevIndex));
    }
  }

  FutureOr<void> _onSeekEvent(
    SeekEvent event,
    Emitter<PlayState> emit,
  ) async {
    try {
      if (state is PlayingState) {
        final currentState = state as PlayingState;
        await audioPlayer.seek(event.position);
        emit(currentState.copyWith(position: event.position));
      }
    } catch (e) {
      emit(ErrorState("Error: No se pudo hacer seek: ${e.toString()}"));
      debugPrint(e.toString());
    }
  }

  FutureOr<void> _onVolumeChangeEvent(
    VolumeChangeEvent event,
    Emitter<PlayState> emit,
  ) async {
    try {
      final clampedVolume = event.volume.clamp(0.0, 1.0);
      await audioPlayer.setVolume(clampedVolume);
      
      if (state is PlayingState) {
        final currentState = state as PlayingState;
        emit(currentState.copyWith(volume: clampedVolume));
      }
    } catch (e) {
      debugPrint("Error changing volume: ${e.toString()}");
    }
  }

  FutureOr<void> _onPitchChangeEvent(
    PitchChangeEvent event,
    Emitter<PlayState> emit,
  ) async {
    try {
      final clampedPitch = event.pitch.clamp(0.5, 2.0);
      await audioPlayer.setPlaybackRate(clampedPitch);
      
      if (state is PlayingState) {
        final currentState = state as PlayingState;
        emit(currentState.copyWith(pitch: clampedPitch));
      }
    } catch (e) {
      debugPrint("Error changing pitch: ${e.toString()}");
      if (state is PlayingState) {
        final currentState = state as PlayingState;
        final clampedPitch = event.pitch.clamp(0.5, 2.0);
        emit(currentState.copyWith(pitch: clampedPitch));
      }
    }
  }

  void _setupListeners() {
    posicion = audioPlayer.onPositionChanged.listen(
      (position) {
        try {
          final currentState = state;
          if (currentState is PlayingState) {
            add(_PositionUpdateEvent(position));
          }
        } catch (e) {
          debugPrint("Error in position listener: ${e.toString()}");
        }
      },
      onError: (error) {
        debugPrint("Position stream error: ${error.toString()}");
      },
    );

    duracion = audioPlayer.onDurationChanged.listen(
      (duration) {
        try {
          final currentState = state;
          if (currentState is PlayingState) {
            add(_DurationUpdateEvent(duration));
          } else if (currentState is LoadingState) {
            add(_DurationUpdateEvent(duration));
          }
        } catch (e) {
          debugPrint("Error in duration listener: ${e.toString()}");
        }
      },
      onError: (error) {
        debugPrint("Duration stream error: ${error.toString()}");
      },
    );

    estado = audioPlayer.onPlayerStateChanged.listen(
      (playerState) {
        try {
          final currentState = state;
          if (currentState is PlayingState) {
            final isPlaying = playerState == PlayerState.playing;
            if (isPlaying != currentState.playing && !_isManualPause) {
              add(_PlayerStateUpdateEvent(isPlaying));
            }
            if (playerState == PlayerState.completed) {
              if (!_isManualPause) {

                add(const NextEvent());
              }
            }
          }
        } catch (e) {
          debugPrint("Error in player state listener: ${e.toString()}");
        }
      },
      onError: (error) {
        debugPrint("Player state stream error: ${error.toString()}");
      },
    );
  }

  @override
  Future<void> close() {
    estado?.cancel();
    posicion?.cancel();
    duracion?.cancel();
    audioPlayer.dispose();
    return super.close();
  }
}

class _PositionUpdateEvent extends PlayerEvent {
  final Duration position;
  _PositionUpdateEvent(this.position);
  
  @override
  List<Object> get props => [position];
}

class _DurationUpdateEvent extends PlayerEvent {
  final Duration duration;
  _DurationUpdateEvent(this.duration);
  
  @override
  List<Object> get props => [duration];
}

class _PlayerStateUpdateEvent extends PlayerEvent {
  final bool isPlaying;
  _PlayerStateUpdateEvent(this.isPlaying);
  
  @override
  List<Object> get props => [isPlaying];
}
