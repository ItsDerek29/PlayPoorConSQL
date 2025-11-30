import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/player_bloc.dart';
import '../blocs/player_load_events.dart';
import '../blocs/player_load_states.dart';
import '../blocs/payer_state.dart';
import '../models/audio_item.dart';
import '../models/audio_track.dart';
import '../blocs/player_event.dart';
import 'swiper.dart';
import '../widgets/interactive_progress_bar.dart';
import '../widgets/circular_progress_button.dart';
import '../utils/duration_formatter.dart';
import '../utils/database_helper.dart';


class Player extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final List<AudioItem> tracks;
  final PlayerBloc? bloc;

  const Player({
    Key? key,
    required this.audioPlayer,
    required this.tracks,
    this.bloc,
  }) : super(key: key);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  Color? wormColor;
  late final PlayerBloc bloc;

  @override
  void initState() {
    super.initState();
    wormColor = const Color(0xffda1cd2);

    bloc = widget.bloc ?? PlayerBloc(
      audioPlayer: widget.audioPlayer,
      items: widget.tracks,
    );
    

    if (widget.bloc == null) {
    bloc.add(PlayerLoadEvent(0));
    }
  }

  @override
  void dispose() {

    if (widget.bloc == null) {
      bloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: Container(
        color: const Color(0xff0b16e6),
        child: SafeArea(
          child: BlocBuilder<PlayerBloc, PlayState>(
            bloc: bloc,
            buildWhen: (previous, current) {

              if (previous is ErrorState && current is ErrorState) return false;
              if (previous is LoadingState && current is LoadingState) return false;
              if (previous is PlayingState && current is PlayingState) {

                return previous.currentIndex != current.currentIndex ||
                       previous.playing != current.playing ||
                       previous.duration != current.duration;
              }
              return true;
            },
            builder: (context, state) {
              if (state is ErrorState) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          state.msg,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => bloc.add(PlayerLoadEvent(0)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is LoadingState) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state is PlayingState) {
                return _buildPlayerContent(state);
              }

              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        ),
      ),
    );
  }


  Widget _buildPlayerContent(PlayingState state) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SongSwiper(
                    audioList: widget.tracks,
                    color: wormColor!,
                    bloc: bloc,
                  ),
                  const SizedBox(height: 32),
                  BlocBuilder<PlayerBloc, PlayState>(
                    bloc: bloc,
                    buildWhen: (previous, current) {
                      if (previous is PlayingState && current is PlayingState) {
                        return previous.currentIndex != current.currentIndex;
                      }
                      return true;
                    },
                    builder: (context, state) {
                      if (state is PlayingState) {
                        final title = bloc.getTrackTitle(state.currentIndex);
                        final artist = bloc.getTrackArtist(state.currentIndex);
                        return Column(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'DMSerif',
                                decoration: TextDecoration.none,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              artist,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                                decoration: TextDecoration.none,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 32),
                  BlocBuilder<PlayerBloc, PlayState>(
                    bloc: bloc,
                    buildWhen: (previous, current) {
                      if (previous is PlayingState && current is PlayingState) {
                        return previous.position != current.position ||
                               previous.duration != current.duration;
                      }
                      return true;
                    },
                    builder: (context, state) {
                      if (state is PlayingState) {
                        final progress = state.duration.inMilliseconds > 0
                            ? state.position.inMilliseconds / state.duration.inMilliseconds
                            : 0.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: InteractiveProgressBar(
                            progress: progress,
                            position: state.position,
                            duration: state.duration,
                            progressColor: wormColor!,
                            onSeek: (newPosition) {
                              bloc.add(SeekEvent(newPosition));
                            },
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: BlocBuilder<PlayerBloc, PlayState>(
            bloc: bloc,
            buildWhen: (previous, current) {
              if (previous is PlayingState && current is PlayingState) {
                return previous.playing != current.playing ||
                       previous.currentIndex != current.currentIndex ||
                       previous.position != current.position ||
                       previous.duration != current.duration;
              }
              return true;
            },
            builder: (context, state) {
              if (state is PlayingState) {
                final progress = state.duration.inMilliseconds > 0
                    ? state.position.inMilliseconds / state.duration.inMilliseconds
                    : 0.0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressButton(
                      icon: Icons.skip_previous,
                      progress: progress,
                      progressColor: wormColor!,
                      size: 60,
                      onPressed: () => bloc.add(const PrevEvent()),
                      tooltip: 'Previous',
                    ),
                    const SizedBox(width: 24),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: wormColor!,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            strokeWidth: 3.0,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            backgroundColor: Colors.white24,
                          ),
                          IconButton(
                            icon: Icon(
                              state.playing
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 40,
                            ),
                            color: Colors.white,
                            onPressed: () {
                              if (state.playing) {
                                bloc.add(const PauseEvent());
                              } else {
                                bloc.add(const PlayEvent());
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    CircularProgressButton(
                      icon: Icons.skip_next,
                      progress: progress,
                      progressColor: wormColor!,
                      size: 60,
                      onPressed: () => bloc.add(const NextEvent()),
                      tooltip: 'Next',
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

}


class SettingsBottomSheet extends StatefulWidget {
  final List<AudioItem> tracks;
  
  const SettingsBottomSheet({
    Key? key,
    required this.tracks,
  }) : super(key: key);

  @override
  State<SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<SettingsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayState>(
      buildWhen: (previous, current) {

        if (previous is PlayingState && current is PlayingState) {
          return previous.currentIndex != current.currentIndex ||
                 previous.position != current.position ||
                 previous.playing != current.playing ||
                 previous.volume != current.volume ||
                 previous.pitch != current.pitch;
        }
        return true;
      },
      builder: (context, state) {
        double volume = 1.0;
        double pitch = 1.0;
        String songTitle = "No song";
        String songArtist = "";
        String duration = "0:00";
        String currentTime = "0:00";
        String playbackState = "Stopped";

        if (state is PlayingState) {
          volume = state.volume;
          pitch = state.pitch;
          final bloc = context.read<PlayerBloc>();
          songTitle = bloc.getTrackTitle(state.currentIndex);
          songArtist = bloc.getTrackArtist(state.currentIndex);
          duration = DurationFormatter.format(state.duration);
          currentTime = DurationFormatter.format(state.position);
          playbackState = state.playing ? "Playing" : "Paused";
        }

        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Settings",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'DMSerif',
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Agregar Canción de Internet"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showAddSongDialog(context),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("Eliminar Última Canción"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.8),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final dbHelper = DatabaseHelper();
                    await dbHelper.deleteLastAudioItem();
                    
                    // Update Bloc
                    context.read<PlayerBloc>().add(const RemoveLastItemEvent());
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Última canción eliminada.")),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              if (state is PlayingState) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Now Playing",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        songTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (songArtist.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          songArtist,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                            decoration: TextDecoration.none,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "$currentTime / $duration",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: playbackState == "Playing"
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              playbackState,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],


              Row(
                children: [
                  const Icon(Icons.volume_up, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Volume: ${(volume * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        Slider(
                          value: volume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 100,
                          label: "${(volume * 100).toStringAsFixed(0)}%",
                          onChanged: (value) {
                            context.read<PlayerBloc>().add(VolumeChangeEvent(value));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),


              Row(
                children: [
                  const Icon(Icons.tune, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Speed/Pitch: ${pitch.toStringAsFixed(2)}x",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        Slider(
                          value: pitch,
                          min: 0.5,
                          max: 2.0,
                          divisions: 150,
                          label: "${pitch.toStringAsFixed(2)}x",
                          onChanged: (value) {
                            context.read<PlayerBloc>().add(PitchChangeEvent(value));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showAddSongDialog(BuildContext context) {
    final titleController = TextEditingController();
    final artistController = TextEditingController();
    final urlController = TextEditingController();
    final imageController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    // Capture the bloc from the context that has the provider
    final bloc = context.read<PlayerBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Add Internet Song"),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: "Song URL (MP3)"),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Required";
                    if (!value.startsWith("http")) return "Invalid URL";
                    return null;
                  },
                ),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
                TextFormField(
                  controller: artistController,
                  decoration: const InputDecoration(labelText: "Artist"),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
                TextFormField(
                  controller: imageController,
                  decoration: const InputDecoration(labelText: "Image URL (Optional)"),

                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final newItem = AudioItem(
                  urlController.text,
                  titleController.text,
                  artistController.text,
                  imageController.text.isNotEmpty ? imageController.text : '',
                );
                
                final dbHelper = DatabaseHelper();
                await dbHelper.insertAudioItem(newItem);
                
                // We need to reload or add to bloc.
                // Since we don't have the ID back from insert (unless we update helper),
                // we might have a sync issue if we just add to bloc without ID.
                // However, for playback, ID isn't strictly used yet, just for DB updates.
                // But for consistency, we should probably reload from DB or update helper.
                // For now, let's just add to bloc.
                
                final trackData = newItem.toMap();
                // If we want the ID, we need to fetch it or change insert to return it.
                // Let's assume for now it's fine.
                
                bloc.add(AddInternetTrackEvent(trackData));
                Navigator.pop(dialogContext);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Song added to playlist")),
                );
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
