import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/payer_state.dart';
import '../blocs/player_bloc.dart';
import '../blocs/player_load_events.dart';
import '../blocs/player_load_states.dart';
import '../models/audio_item.dart';


class SongSwiper extends StatefulWidget {
  final List<AudioItem> audioList; // Solo para compatibilidad, ahora usa el BLoC
  final Color color;
  final PlayerBloc bloc;

  const SongSwiper({
    Key? key,
    required this.audioList,
    required this.color,
    required this.bloc,
  }) : super(key: key);

  @override
  _SongSwiperState createState() => _SongSwiperState();
}

class _SongSwiperState extends State<SongSwiper> {
  late PageController pageController;
  int _currentPage = 0;
  bool _isUserScrolling = false;
  bool _isUpdatingFromState = false;

  @override
  void initState() {
    super.initState();
    pageController = PageController(viewportFraction: 0.8, initialPage: 0);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlayerBloc, PlayState>(
      bloc: widget.bloc,
      listener: (context, state) {

        if (!_isUserScrolling && !_isUpdatingFromState) {
          int newIndex = 0;
          if (state is PlayingState) {
            newIndex = state.currentIndex;
          } else if (state is LoadingState && state.currentIndex != null) {
            newIndex = state.currentIndex!;
          }

          if (newIndex != _currentPage && pageController.hasClients) {
            _currentPage = newIndex;
            _isUpdatingFromState = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (pageController.hasClients && 
                  pageController.page?.round() != newIndex) {
                pageController.animateToPage(
                  newIndex,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ).then((_) {
                  _isUpdatingFromState = false;
                });
              } else {
                _isUpdatingFromState = false;
              }
            });
          }
        }
      },
      child: BlocBuilder<PlayerBloc, PlayState>(
        bloc: widget.bloc,
        buildWhen: (previous, current) {

          int prevIndex = 0;
          int currIndex = 0;
          if (previous is PlayingState) prevIndex = previous.currentIndex;
          if (current is PlayingState) currIndex = current.currentIndex;
          if (previous is LoadingState && previous.currentIndex != null) {
            prevIndex = previous.currentIndex!;
          }
          if (current is LoadingState && current.currentIndex != null) {
            currIndex = current.currentIndex!;
          }
          if (previous is PlayingState && current is PlayingState) {
            return previous.currentIndex != current.currentIndex || 
                   previous.playlistSignature != current.playlistSignature;
          }
          if (previous is LoadingState && current is LoadingState) {
             return previous.currentIndex != current.currentIndex ||
                    previous.playlistSignature != current.playlistSignature;
          }
          return true;
        },
        builder: (context, state) {
          int currentIndex = 0;
          if (state is PlayingState) {
            currentIndex = state.currentIndex;
          } else if (state is LoadingState && state.currentIndex != null) {
            currentIndex = state.currentIndex!;
          }

          return Column(
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.4,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification) {
                      _isUserScrolling = true;
                    } else if (notification is ScrollEndNotification) {
                      _isUserScrolling = false;
                    }
                    return false;
                  },
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: widget.bloc.totalCanciones,
                    onPageChanged: (index) {

                      if (!_isUpdatingFromState) {
                        _isUserScrolling = false;
                        _currentPage = index;

                        final currentState = widget.bloc.state;
                        if (currentState is PlayingState && index != currentState.currentIndex) {
                          widget.bloc.add(PlayerLoadEvent(index));
                        } else if (currentState is LoadingState && 
                                   currentState.currentIndex != null && 
                                   index != currentState.currentIndex) {
                          widget.bloc.add(PlayerLoadEvent(index));
                        }
                      }
                    },
                  itemBuilder: (context, index) {
                    // Obtener información de la canción desde el BLoC
                    final imagePath = widget.bloc.getTrackImage(index);
                    final title = widget.bloc.getTrackTitle(index);
                    final artist = widget.bloc.getTrackArtist(index);

                    return Hero(
                      tag: 'song_image_$index',
                      child: GestureDetector(
                        onTap: () {

                          if (index != currentIndex) {
                            widget.bloc.add(PlayerLoadEvent(index));
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: imagePath != null
                                ? (_isNetworkImage(imagePath)
                                    ? Image.network(
                                        imagePath,
                                        fit: BoxFit.cover,
                                        key: ValueKey('${imagePath}_$index'),
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return _buildPlaceholderImage(title, artist);
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildPlaceholderImage(title, artist);
                                        },
                                      )
                                    : Image.asset(
                                        imagePath,
                                        fit: BoxFit.cover,
                                        key: ValueKey('${imagePath}_$index'),
                                        cacheWidth: 800,
                                        cacheHeight: 800,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildPlaceholderImage(title, artist);
                                        },
                                      ))
                                : _buildPlaceholderImage(title, artist),
                          ),
                        ),
                      ),
                    );
                  },
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Page indicator dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.bloc.totalCanciones,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == currentIndex ? widget.color : Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderImage(String title, String artist) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xffda1cd2),
            const Color(0xff0b16e6),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.music_note,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (artist.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                artist,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }
}
