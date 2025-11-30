import 'package:playbloc/blocs/payer_state.dart';
import 'package:playbloc/blocs/player_event.dart';
import 'package:playbloc/blocs/player_load_events.dart';
import 'package:playbloc/blocs/player_load_states.dart';
import 'package:playbloc/widgets/interactive_progress_bar.dart';
import 'package:playbloc/widgets/circular_progress_button.dart';
import 'package:playbloc/utils/duration_formatter.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slider_drawer/flutter_slider_drawer.dart';
import '../blocs/player_bloc.dart';
import '../views/player.dart';
import '../models/audio_item.dart';

class DrawerMenu extends StatefulWidget {
  final Widget child;
  final List<AudioItem> tracks;

  const DrawerMenu({
    Key? key,
    required this.child,
    required this.tracks,
  }) : super(key: key);

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  final GlobalKey<SliderDrawerState> sliderDrawerKey = GlobalKey();

  void _showSettingsBottomSheet(BuildContext context) {
    final bloc = context.read<PlayerBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BlocProvider.value(
        value: bloc,
        child: SettingsBottomSheet(tracks: widget.tracks),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliderDrawer(
      key: sliderDrawerKey,
      appBar: AppBar(
        backgroundColor: const Color(0xff0b16e6),
        title: const Text(
          "PlayPoor",
          style: TextStyle(
            fontFamily: 'DMSerif',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showSettingsBottomSheet(context),
            tooltip: 'Settings',
          ),
        ],
      ),
      slider: MenuWidget(
        onItemSelected: (title) {
          sliderDrawerKey.currentState?.closeSlider();
          if (title == "Settings") {
            _showSettingsBottomSheet(context);
          } else if (title == "About") {
            _showAboutDialog(context);
          }
        },
      ),
      child: widget.child,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "About",
          style: TextStyle(
            fontFamily: 'DMSerif',
            decoration: TextDecoration.none,
          ),
        ),
        content: const Text(
          "Aplicación hecha por Derek Chávez",
          style: TextStyle(
            decoration: TextDecoration.none,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}

class MenuWidget extends StatelessWidget {
  final Function(String) onItemSelected;

  const MenuWidget({
    Key? key,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PlayerBloc>();
    final wormColor = const Color(0xffda1cd2);

    return Material(
      color: const Color(0xff0b16e6),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [

                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xffda1cd2),
                        Color(0xff0b16e6),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.music_note,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "PlayPoor",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'DMSerif',
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Aplicación hecha por Derek Chávez",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),


                _buildMenuItem(
                  context,
                  icon: Icons.home,
                  title: "Home",
                  onTap: () => onItemSelected("Home"),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.settings,
                  title: "Settings",
                  onTap: () => onItemSelected("Settings"),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.queue_music,
                  title: "Playlist",
                  onTap: () => onItemSelected("Playlist"),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.info,
                  title: "About",
                  onTap: () => onItemSelected("About"),
                ),
              ],
            ),
          ),
          

          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              border: const Border(
                top: BorderSide(color: Colors.white12, width: 1),
              ),
            ),
            child: BlocBuilder<PlayerBloc, PlayState>(
              bloc: bloc,
              buildWhen: (previous, current) {
                if (previous is PlayingState && current is PlayingState) {
                  return previous.currentIndex != current.currentIndex ||
                         previous.playing != current.playing ||
                         previous.position != current.position ||
                         previous.duration != current.duration;
                }
                return true;
              },
              builder: (context, state) {
                if (state is PlayingState) {
                  final title = bloc.getTrackTitle(state.currentIndex);
                  final artist = bloc.getTrackArtist(state.currentIndex);
                  final progress = state.duration.inMilliseconds > 0
                      ? state.position.inMilliseconds / state.duration.inMilliseconds
                      : 0.0;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          decoration: TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        artist,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          decoration: TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      InteractiveProgressBar(
                        progress: progress,
                        position: state.position,
                        duration: state.duration,
                        progressColor: wormColor,
                        onSeek: (newPosition) {
                          bloc.add(SeekEvent(newPosition));
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressButton(
                            icon: Icons.skip_previous,
                            progress: progress,
                            progressColor: wormColor,
                            size: 40,
                            onPressed: () => bloc.add(const PrevEvent()),
                            tooltip: 'Previous',
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: wormColor,
                            ),
                            child: IconButton(
                              icon: Icon(
                                state.playing ? Icons.pause : Icons.play_arrow,
                                size: 24,
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
                          ),
                          const SizedBox(width: 16),
                          CircularProgressButton(
                            icon: Icons.skip_next,
                            progress: progress,
                            progressColor: wormColor,
                            size: 40,
                            onPressed: () => bloc.add(const NextEvent()),
                            tooltip: 'Next',
                          ),
                        ],
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          decoration: TextDecoration.none,
        ),
      ),
      onTap: onTap,
      hoverColor: Colors.white.withOpacity(0.1),
    );
  }
}
